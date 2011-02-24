/*
 * gstd/src/gstd-pipeline.vala
 *
 * GStreamer daemon Pipeline class - framework for controlling audio and video streaming using D-Bus messages
 *
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
 *
 * GPL2 license - See http://www.opensource.org/licenses/gpl-2.0.php for complete text.
 */

using Gst;

[DBus (name = "com.ridgerun.gstreamer.gstd.PipelineInterface", signals = "EoS",
       signals = "StateChanged", signals = "Error", signals = "QoS")]

public class Pipeline : GLib.Object
{
	/* Private data */
	private Gst.Element pipeline;
	private uint64 id = 0;
	private bool initialized = false;
	private string path = "";
	private double rate = 1.0;
	//private uint _counter = 0;
	private ulong windowId = 0;

	public signal void EoS (uint64 pipe_id);
	public signal void StateChanged (uint64 pipe_id, State old_state, State new_state, string src);
	public signal void Error (uint64 pipe_id, string err_message);
	public signal void QoS (uint64 pipe_id,
                                bool live, 
	                        uint64 running_time,
	                        uint64 stream_time,
	                        uint64 timestamp,
	                        uint64 duration,
	                        int64 jitter,
	                        double proportion,
	                        int quality,
	                        int format,
	                        uint64 processed,
	                        uint64 dropped);

	/**
	   Create a new instance of a Pipeline
	   @param description, gst-launch style string description of the pipeline
	   @param ids, pipeline identifier
	 */
	public Pipeline (string description)
	{
		try
		{
			/* Create the pipe */
			this.pipeline = parse_launch (description) as Element;

			/*Get and watch bus */
			Gst.Bus bus = pipeline.get_bus ();
			bus.set_sync_handler(bus_sync_callback);
			bus.add_watch (bus_callback);
			/* The bus watch increases our ref count, so we need to unreference
			 * ourselfs in order to provide properly release behavior of this
			 * object
			 */
			g_object_unref (this);

			/* Set pipeline state to initialized */
			initialized = true;

			if (this.PipelineIsInitialized ())
				Posix.syslog (Posix.LOG_NOTICE, "Pipeline created, %s", description);
			else
				Posix.syslog (Posix.LOG_ERR, "Pipeline could not be initialized");
		}
		catch (GLib.Error e)
		{
			Posix.syslog (Posix.LOG_ERR, "Error constructing pipeline, %s", e.message);
		}
	}

	/**
	   Destroy a instance of a Pipeline
	 */
	~Pipeline ()
	{
		/* Destroy the pipeline */
		if (this.PipelineIsInitialized())
		{
			if (!PipelineSetStateImpl (State.NULL))
				Posix.syslog (Posix.LOG_ERR, "Failed to destroy pipeline");
		}
	}

	private BusSyncReply bus_sync_callback (Gst.Bus bus, Gst.Message message)
	{
		if (windowId == 0)
			return BusSyncReply.PASS;

		unowned Structure ? st = message.get_structure();
		if (!(st != null && st.has_name("prepare-xwindow-id")))
			return BusSyncReply.PASS;

		Posix.syslog (Posix.LOG_DEBUG, "requested xwindow-id");
		var pipe = pipeline as Gst.Pipeline;
		assert(pipe != null);

		var sink = pipe.get_child_by_name("videosink") as Element;
		if (sink == null)
			return BusSyncReply.PASS;

		var overlay = sink as Gst.XOverlay;
		if (overlay == null)
			return BusSyncReply.PASS;

		Posix.syslog (Posix.LOG_DEBUG, "set xwindow-id %lu", windowId);
		overlay.set_xwindow_id(windowId);

		return BusSyncReply.PASS;
	}

	private bool bus_callback (Gst.Bus bus, Gst.Message message)
	{
		Posix.syslog (Posix.LOG_DEBUG, "received message %s", message.type.to_string());
		switch (message.type)
		{
			case MessageType.ERROR :

				GLib.Error err;
				string dbg;

				/*Parse error */
				message.parse_error (out err, out dbg);

				/*Sending Error Signal */
				Error (PipelineGetId(), err.message);

				Posix.syslog (Posix.LOG_DEBUG, "Error on pipeline, %s", err.message);
				break;

			case MessageType.EOS:

				/*Sending Eos Signal */
				EoS (PipelineGetId());
				break;

			case MessageType.STATE_CHANGED:

				Gst.State oldstate;
				Gst.State newstate;
				Gst.State pending;

				string src = ((Element)message.src).get_name ();
				message.parse_state_changed (out oldstate, out newstate,
				                             out pending);
				
				Posix.syslog (Posix.LOG_INFO, "%s,changes state from %s to %s", src, oldstate.to_string (), newstate.to_string ());

				/*Sending StateChanged Signal */
				StateChanged (PipelineGetId(), oldstate, newstate, src);
				break;

			/*case MessageType.INFO:
			   Posix.syslog (Posix.LOG_DEBUG, "received info message");
			   if (message.src == pipeline)
			   {
			    uint counter = 0;
			    unowned Gst.Structure st = message.get_structure();
			    if (st != null && st.get_name() == "keepalive" && st.get_uint("counter", out counter))
			    {
			      _counter = counter;
			      Posix.syslog (Posix.LOG_DEBUG, "received keep alive %u", _counter);
			    }
			   }
			   break;*/
#if GSTREAMER_SUPPORT_QOS_SIGNAL
			case MessageType.QOS:
				bool live;
		                uint64 running_time;
		                uint64 stream_time;
		                uint64 timestamp;
		                uint64 duration;
		                int64 jitter;
		                double proportion;
		                int quality;
		                int format;
		                uint64 processed;
		                uint64 dropped;

				//plase note, if this doesn't compile, you need to apply gstreamer-0.10.vapi.patch
				message.parse_qos(out live, out running_time, out stream_time, out timestamp, out duration);
				message.parse_qos_values(out jitter, out proportion, out quality);
				Format fmt;
				message.parse_qos_stats(out fmt, out processed, out dropped);
				format = fmt;

				QoS(PipelineGetId(), live, running_time, stream_time, timestamp, duration, jitter, proportion, quality, format, processed, dropped);
				break;
#endif
			default:
				break;
		}

		return true;
	}

	private bool PipelineSetStateImpl (State state)
	{
		pipeline.set_state (state);

		/* Wait until state change is done */
		State current, pending;
		this.pipeline.get_state (out current, out pending, (Gst.ClockTime)(Gst.CLOCK_TIME_NONE)); // Block
		if (current != state)
		{
			Posix.syslog (Posix.LOG_ERR, "Pipeline failed to change state to %s", state.to_string ());
			return false;
		}
		return true;
	}

	public bool PipelineSetState (int state)
	{
		return PipelineSetStateImpl((State)(state));
	}
	
	private void PipelineAsyncSetStateImpl(State state)
	{
		pipeline.set_state (state);
		Posix.syslog (Posix.LOG_DEBUG, "Asynchronous state change to %s", state.to_string());
	}
	
	public void PipelineAsyncSetState(int state)
	{
		PipelineAsyncSetStateImpl((State)(state));
	}

	/**
	   Returns initialized flag value.
	 */
	public bool PipelineIsInitialized ()
	{
		return this.initialized;
	}

	/**
           Gets the id of the pipe.
          */
	public uint64 PipelineGetId()
	{
		return this.id;
	}

	/**
           Sets the id of the pipe.
          */
	public void PipelineSetId(uint64 id)
	{
		this.id = id;
	}

	/**
	   Returns the dbus-path assigned when created
	 */
	public string PipelineGetPath ()
	{
		return this.path;
	}

	/**
	   Sets a dbus-path,this is assigned when connected to daemon
	 */
	public bool PipelineSetPath (string dbuspath)
	{
		this.path = dbuspath;
		return true;
	}

	/**
	   Gets the pipeline state
	 */
	public int PipelineGetState ()
	{
		State current, pending;
		pipeline.get_state (out current, out pending, (Gst.ClockTime)(Gst.CLOCK_TIME_NONE)); // Block
		return current;
	}

	/**
	   Sets a boolean property for an element on the pipeline
	   @param element, whose property needs to be set
	   @param property,property name
	   @param val, bool property value
	 */
	public bool ElementSetPropertyBoolean (string element, string property, bool val)
	{
		Gst.Element e;
		Gst.Pipeline pipe;
		GLib.ParamSpec spec;

		pipe = pipeline as Gst.Pipeline;
		e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.set (property, val, null);
		return true;
	}

	/**
	   Sets an int property for an element on the pipeline
	   @param element, whose property needs to be set
	   @param property,property name
	   @param val, int property value
	 */
	public bool ElementSetPropertyInt (string element, string property, int val)
	{
		Element e;
		Gst.Pipeline pipe;
		GLib.ParamSpec spec;

		pipe = pipeline as Gst.Pipeline;
		e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Gstd: Element %s does not have the property %s",
				              element, property);
			return false;
		}
		e.set (property, val, null);

		return true;
	}

	/**
	   Sets an long property for an element on the pipeline
	   @param element, whose property needs to be set
	   @param property,property name
	   @param val, long property value     */
	public bool ElementSetPropertyInt64 (string element, string property, int64 val)
	{
		Element e;
		Gst.Pipeline pipe;
		GLib.ParamSpec spec;

		pipe = pipeline as Gst.Pipeline;
		e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.set (property, val, null);
		return true;
	}

	/**
	   Sets a string property for an element on the pipeline
	   @param element, whose property needs to be set
	   @param property,property name
	   @param val,string property value
	 */
	public bool ElementSetPropertyString (string element, string property, string val)
	{
		Element e;
		Gst.Pipeline pipe;
		GLib.ParamSpec spec;

		pipe = pipeline as Gst.Pipeline;
		e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.set (property, val, null);

		return true;
	}

	/**
	   Gets an element's bool property value of a specific pipeline
	   @param element, whose property value wants to be known
	   @param property,property name
	 */
	public bool ElementGetPropertyBoolean (string element, string property, out bool val)
	{
		val = false;

		Gst.Pipeline pipe = pipeline as Gst.Pipeline;
		Element e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.get (property, &val, null);
		return true;
	}

	/**
	   Gets an element's int property value of a specific pipeline
	   @param element, whose property value wants to be known
	   @param property,property name
	   @param val value of the property
	 */
	public bool ElementGetPropertyInt (string element, string property, out int val)
	{
		val = 0;

		Gst.Pipeline pipe = pipeline as Gst.Pipeline;
		Element e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.get (property, &val, null);
		return true;
	}

	/**
	   Gets an element's long property value of a specific pipeline
	   @param element, whose property value wants to be known
	   @param property,property name
	   @param val value of the property
	 */
	public bool ElementGetPropertyInt64 (string element, string property, out int64 val)
	{
		val = 0;

		Gst.Pipeline pipe = pipeline as Gst.Pipeline;
		Element e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.get (property, &val, null);
		return true;
	}

	/**
	   Gets an element's string property value of a specific pipeline
	   @param element, whose property value wants to be known
	   @param property,property name
	   @param val value of the property
	 */
	public bool ElementGetPropertyString (string element, string property, out string val)
	{
		val = "";

		Gst.Pipeline pipe = pipeline as Gst.Pipeline;
		Element e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.get (property, &val, null);
		return true;
	}
	
	/**
	   Gets an element's state value of a specific pipeline
	   @param element, whose property value wants to be known
	   @param val value of the property
	 */
	public int ElementGetState (string element)
	{
		//Posix.syslog (Posix.LOG_INFO, "Searching element %s on pipeline.", element);
		Gst.Pipeline pipe = pipeline as Gst.Pipeline;

		Element e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline %s", element, pipe.get_name());
			return State.NULL;
		}
		
		// Simply return the current state. Ignore possible state changes
		State current, pending;
		e.get_state ( out current, out pending, (Gst.ClockTime)(Gst.CLOCK_TIME_NONE)); // Block
		return current;
	}

	/**
	   Gets an element's buffer property value of a specific pipeline
	   @param element, whose property value wants to be known
	   @param property,property name
	   @param caps caps of buffer
	   @param data data
	 */
	public bool ElementGetPropertyBuffer (string element, string property, out string caps, out uint8[] data)
	{
		caps = "";
		data = new uint8[0];

		Gst.Pipeline pipe = pipeline as Gst.Pipeline;
		Element e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		Gst.Buffer buffer = null;
		e.get (property, &buffer, null);

		if (buffer != null)
		{
			caps = (buffer.caps != null) ? buffer.caps.to_string() : "";
			data = buffer.data;
		}

		return true;
	}

	/**
	   Query duration to a pipeline on the server
	   @return time in milliseconds or null if not available
	 */
	public int64 PipelineGetDuration ()
	{
		Format format = Gst.Format.TIME;
		int64 duration = 0;

		/* Query duration */
		if (!pipeline.query_duration (ref format, out duration))
		{
			return -1;
		}

		if (duration == Gst.CLOCK_TIME_NONE)
			return -1;

		Posix.syslog (Posix.LOG_DEBUG, "Duration at server is %u:%02u:%02u.%03u",
			      (uint)(duration / (SECOND * 60 * 60)),
			      (uint)((duration / (SECOND * 60)) % 60),
			      (uint)((duration / SECOND) % 60),
			      (uint)(duration % SECOND));

		return duration;
	}

	/**
	   Query position to a pipeline on the server
	   @return position in milliseconds or null if not available
	 */
	public int64 PipelineGetPosition ()
	{
		Format format = Gst.Format.TIME;
		int64 position = 0;

		if (!pipeline.query_position (ref format, out position))
		{
			return -1;
		}

		if (position == Gst.CLOCK_TIME_NONE)
			return -1;

		Posix.syslog (Posix.LOG_DEBUG, "Position at server is %u:%02u:%02u.%03u",
			      (uint)(position / (SECOND * 60 * 60)),
			      (uint)((position / (SECOND * 60)) % 60),
			      (uint)((position / SECOND) % 60),
			      (uint)(position % SECOND));
		return position;
	}

	/**
	   Seeks a specific time position.
	   Data in the pipeline is flushed.
	   @param ipos_ms, absolute position in milliseconds
	 */
	public bool PipelineSeek (int64 ipos_ns)
	{
		/*Set the current position */
		if (!pipeline.seek (rate, Gst.Format.TIME, Gst.SeekFlags.FLUSH, Gst.SeekType.SET, ipos_ns, Gst.SeekType.NONE, CLOCK_TIME_NONE))
		{
			Posix.syslog (Posix.LOG_WARNING, "Media type not seekable");
			return false;
		}
		return true;
	}

	/**
	   Seeks a specific time position.
	   Data in the pipeline is flushed.
	   @param ipos_ms, absolute position in milliseconds
	 */
	public void PipelineAsyncSeek (int64 ipos_ms)
	{
		PipelineSeek(ipos_ms);
	}

	/**
	   Skips time, it moves position forward and backwards from
	   the current position.
	   Data in the pipeline is flushed.
	   @param period_ms, relative time in milliseconds
	 */
	public bool PipelineSkip (int64 period_ns)
	{
		Gst.Format format = Gst.Format.TIME;
		Gst.SeekFlags flag = Gst.SeekFlags.FLUSH;
		Gst.SeekType cur_type = Gst.SeekType.SET;
		Gst.SeekType stp_type = Gst.SeekType.NONE;
		int64 stp_pos_ns = CLOCK_TIME_NONE;
		int64 cur_pos_ns = 0;
		int64 seek_ns = 0;

		/*Gets the current position */
		if (!pipeline.query_position (ref format, out cur_pos_ns))
		{
			return false;
		}

		/*Sets the new position relative to the current one */
		seek_ns = cur_pos_ns + period_ns;

		/*Set the current position */
		if (!pipeline.seek (rate, format, flag, cur_type, seek_ns, stp_type,
		                    stp_pos_ns))
		{
			Posix.syslog (Posix.LOG_WARNING, "Media type not seekable");
			return false;
		}
		return true;
	}

	/**
	   Changes pipeline speed, it enable fast|slow foward and
	   fast|slow -reverse playback
	   @param new_rate, values great than zero play forward, reverse
	        otherwise.  Values greater than 1 (or -1 for reverse)
	        play faster than normal, otherwise slower than normal.
	 */
	public bool PipelineSpeed (double new_rate)
	{
		Gst.Format format = Gst.Format.TIME;
		Gst.SeekFlags flag = Gst.SeekFlags.SKIP | Gst.SeekFlags.FLUSH;
		Gst.SeekType type = Gst.SeekType.NONE;
		int64 pos_ns = CLOCK_TIME_NONE;

		/*Sets the new rate */
		rate = new_rate;

		/*Changes the rate on the pipeline */
		if (!pipeline.seek (rate, format, flag, type, pos_ns, type, pos_ns))
		{
			Posix.syslog (Posix.LOG_WARNING, "Speed could not be changed");
			return false;
		}
		return true;
	}

	public void PipelineSendEoS ()
	{
		pipeline.send_event(new Event.eos());
	}

	public void PipelineStep (uint64 frames)
	{
		PipelineSetState (State.PAUSED);
		pipeline.send_event(new Event.step(Format.BUFFERS,frames,1.0,true,false));
	}

	public bool PipelineSendCustomEvent(string stype, string name)
	{
		EventType type;

		switch (stype.down () ) {
			case "upstream":
				type = EventType.CUSTOM_UPSTREAM;
				break;
			case "downstream":
				type = EventType.CUSTOM_DOWNSTREAM;
				break;
			case "downstream_oob":
				type = EventType.CUSTOM_DOWNSTREAM_OOB;
				break;
			case "both":
				type = EventType.CUSTOM_BOTH;
				break;
			case "both_oob":
				type = EventType.CUSTOM_BOTH_OOB;
				break;
			default:
				return false;
		}
		pipeline.send_event(new Event.custom(type,
			new Structure.empty(name)));
		return true;
	}

	/*public void SendNewCounterEvent(uint counter) {
	   Posix.syslog (Posix.LOG_DEBUG, "Send keep alive event ...");
	   Gst.Structure st = new Gst.Structure("keepalive", "counter", typeof(uint), counter, null);
	   Gst.Event evt = new Gst.Event.sink_message(new Gst.Message.custom (Gst.MessageType.INFO, pipeline, st));
	   //evt.type = Gst.EventType.CUSTOM_DOWNSTREAM;
	   bool success = pipeline.send_event(evt);
	   Posix.syslog (Posix.LOG_DEBUG, "... sent keep alive event (%s)", success.to_string());
	   }*/

	/**
	   Sets an element to the specified state
	   @param element, whose state is to be set
	   @param state, desired element state
	 */
	public bool ElementSetState (string element, int state)
	{
		Element e;
		Gst.Pipeline pipe;
		State current, pending;

		pipe = pipeline as Gst.Pipeline;
		e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		e.set_state ((State)(state));

		/* Wait for the transition at most 8 secs */
		e.get_state (out current, out pending,
				    (Gst.ClockTime) 4000000000u);
		e.get_state (out current, out pending,
				    (Gst.ClockTime) 4000000000u);
		if (current != state)
		{
			Posix.syslog (Posix.LOG_ERR, "Element, failed to change state %s", state.to_string ());
			return false;
		}
		return true;
	}

	/**
	   Sets an element to the specified state, returning before the state change may have occurred
	   @param element, whose state is to be set
	   @param state, desired element state
	 */
	public void ElementAsyncSetState (string element, int state)
	{
		Element e;
		Gst.Pipeline pipe;

		pipe = pipeline as Gst.Pipeline;
		e = pipe.get_child_by_name (element) as Element;
		if (e == null)
		{
			Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
		}
		e.set_state ((State)(state));
	}

	public void SetWindowId(uint64 winId)    //use uint64, because dbus-binding can't map type "ulong"
	{
		windowId = (ulong)(winId);
	}
	
	/**
	   Ping pipeline..
	   @return true if alive
	 */
	public bool Ping ()
	{
		return true;
	}

	/*public uint GetCounter() {
	   return _counter;
	   }

	   public void SetCounter(uint c) {
	   _counter = c;
	   } */
}
