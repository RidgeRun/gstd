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

[DBus (name = "com.ridgerun.gstreamer.gstd.PipelineInterface", signals = "EOS",
       signals = "StateChanged", signals = "Error")]

public class Pipeline : GLib.Object
{
	/* Private data */
	private Gst.Element pipeline;
	private bool debug = false;
	private bool initialized = false;
	private string path = "";
	private double rate = 1.0;
	//private uint _counter = 0;
	private ulong windowId = 0;

	public signal void Eos ();
	public signal void StateChanged (string old_state, string new_state, string src);
	public signal void Error (string err_message);

	/**
	   Create a new instance of a Pipeline
	   @param description, gst-launch style string description of the pipeline
	   @param ids, pipeline identifier
	   @param _debug, flag to enable debug information
	 */
	public Pipeline (string description, bool _debug)
	{
		try
		{
			/* Create the pipe */
			pipeline = parse_launch (description) as Element;

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

			this.debug = _debug;

			if (_debug)
			{
				if (this.PipelineIsInitialized ())
					Posix.syslog (Posix.LOG_NOTICE, "Pipeline created, %s", description);
				else
					Posix.syslog (Posix.LOG_ERR, "Pipeline could not be initialized");
			}
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
			if (!PipelineSetState (State.NULL))
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
				Error (err.message);

				if (debug)
					Posix.syslog (Posix.LOG_DEBUG, "Error on pipeline, %s", err.message);
				break;

			case MessageType.EOS:

				/*Sending Eos Signal */
				Eos ();
				break;

			case MessageType.STATE_CHANGED:

				Gst.State oldstate;
				Gst.State newstate;
				Gst.State pending;

				string src = ((Element)message.src).get_name ();
				message.parse_state_changed (out oldstate, out newstate,
				                             out pending);
				if (debug)
					Posix.syslog (Posix.LOG_INFO, "%s,changes state from %s to %s", src,
					              oldstate.to_string (), newstate.to_string ());

				/*Sending StateChanged Signal */
				StateChanged (oldstate.to_string (), newstate.to_string (), src);
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

			default:
				break;
		}

		return true;
	}

	private bool PipelineSetState (State state)
	{
		State current, pending;

		pipeline.set_state (state);
		/* Wait for the transition at most 8 secs */
		pipeline.get_state (out current, out pending,
		                    (Gst.ClockTime) 4000000000u);
		pipeline.get_state (out current, out pending,
		                    (Gst.ClockTime) 4000000000u);
		if (current != state)
		{
			if (debug)
				Posix.syslog (Posix.LOG_ERR, "Element, failed to change state %s",
				              state.to_string ());
			return false;
		}
		return true;
	}

	/**
	   Returns initialized flag value.
	 */
	public bool PipelineIsInitialized ()
	{
		return this.initialized;
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
	public string PipelineGetState ()
	{
		State current, pending;

		pipeline.get_state (out current, out pending,
		                    (Gst.ClockTime) 2000000000u);
		return current.to_string ();
	}

	/**
	   Sets a pipeline to play state. Returns when the pipeline has
	   already reached that state.
	 */
	public bool PipelinePlay ()
	{
		return PipelineSetState (State.PLAYING);
	}

	/**
	   Sets a pipeline to play state. Returns immediately
	 */
	public void PipelineAsyncPlay ()
	{
		pipeline.set_state (State.PLAYING);
		if (debug)
			Posix.syslog (Posix.LOG_DEBUG, "Asynchronous state change to playing");
	}

	/**
	   Sets a pipeline to ready state. Returns when the pipeline has
	   already reached that state.
	 */
	public bool PipelineReady ()
	{
		return PipelineSetState (State.READY);
	}

	/**
	   Sets a pipeline to ready state. Returns immediately
	 */
	public void PipelineAsyncReady ()
	{
		pipeline.set_state (State.READY);
		if (debug)
			Posix.syslog (Posix.LOG_DEBUG, "Asynchronous state change to ready");
	}

	/**
	   Sets a pipeline to paused state. Returns when the pipeline has
	   already reached that state.
	 */
	public bool PipelinePause ()
	{
		return PipelineSetState (State.PAUSED);
	}

	/**
	   Sets a pipeline to paused state. Returns immediately
	 */
	public void PipelineAsyncPause ()
	{
		pipeline.set_state (State.PAUSED);
		if (debug)
			Posix.syslog (Posix.LOG_DEBUG, "Asynchronous state change to pause");
	}

	/**
	   Sets a pipeline to null state. Returns when the pipeline has already
	   reached that state.
	   On this state the pipeline releases all allocated resources, but can
	   be reused again.
	 */
	public bool PipelineNull ()
	{
		return PipelineSetState (State.NULL);
	}

	/**
	   Sets a pipeline to null state. Returns immediately
	 */
	public void PipelineAsyncNull ()
	{
		pipeline.set_state (State.NULL);
		if (debug)
			Posix.syslog (Posix.LOG_DEBUG, "Asynchronous state change to null");
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline",
				              element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s does not have the property %s",
				              element, property);
			return false;
		}

		e.get (property, &val, null);
		return true;
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
			if (debug)
				Posix.syslog (Posix.LOG_WARNING, "Element %s not found on pipeline", element);
			return false;
		}

		GLib.ParamSpec spec = e.get_class ().find_property (property);
		if (spec == null)
		{
			if (debug)
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

		if (debug)
		{
			Posix.syslog (Posix.LOG_DEBUG, "Duration at server is %u:%02u:%02u.%03u",
			              (uint)(duration / (SECOND * 60 * 60)),
			              (uint)((duration / (SECOND * 60)) % 60),
			              (uint)((duration / SECOND) % 60),
			              (uint)(duration % SECOND));
		}
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

		if (debug)
		{
			Posix.syslog (Posix.LOG_DEBUG, "Position at server is %u:%02u:%02u.%03u",
			              (uint)(position / (SECOND * 60 * 60)),
			              (uint)((position / (SECOND * 60)) % 60),
			              (uint)((position / SECOND) % 60),
			              (uint)(position % SECOND));
		}
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
			if (debug)
			{
				Posix.syslog (Posix.LOG_WARNING, "Media type not seekable");
				return false;
			}
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
			if (debug)
			{
				Posix.syslog (Posix.LOG_WARNING, "Media type not seekable");
				return false;
			}
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
			if (debug)
			{
				Posix.syslog (Posix.LOG_WARNING, "Speed could not be changed");
				return false;
			}
		}
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

	public void SetWindowId(uint64 winId)    //use uint64, because dbus-binding can't map type "ulong"
	{
		windowId = (ulong)(winId);
	}

	/*public uint GetCounter() {
	   return _counter;
	   }

	   public void SetCounter(uint c) {
	   _counter = c;
	   } */
}
