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

     public class Pipeline:GLib.Object
     {

       /* Private data */
       private Gst.Element pipeline;
       private bool debug = false;
       private bool initialized = false;
       private string path = "";
       private double rate = 1.0;

       public signal void Eos ();
       public signal void StateChanged (string old_state, string new_state,
           string src);
       public signal void Error (string err_message);


    /**
     Create a new instance of a Pipeline
     @param description, gst-launch style string description of the pipeline
     @param ids, pipeline identifier
     @param _debug, flag to enable debug information
     */
       public Pipeline (string description, bool _debug)
       {

         try {
           /* Create the pipe */
           pipeline = parse_launch (description) as Element;

           /*Get and watch bus */
             Gst.Bus bus = pipeline.get_bus ();
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
               stdout.printf ("Gstd: Pipeline created, %s\n", description);
             else
               stderr.printf ("Gstd: Pipeline could not be initialized\n");
           }
         }
         catch (GLib.Error e)
         {
           stderr.printf ("Gstd: Error constructing pipeline, %s\n", e.message);
         }
       }

    /**
     Destroy a instance of a Pipeline 
     */
       ~Pipeline () {
         /* Destroy the pipeline */
         if(this.PipelineIsInitialized()){
           if (!PipelineSetState (State.NULL))
             stderr.printf ("Gstd: Failed to destroy pipeline\n");
         }
       }

       private bool bus_callback (Gst.Bus bus, Gst.Message message)
       {
         switch (message.type) {
           case MessageType.ERROR:

             GLib.Error err;
             string dbg;

             /*Parse error */
             message.parse_error (out err, out dbg);

             /*Sending Error Signal */
             Error (err.message);

             if (debug)
               stderr.printf ("Gstd: Error on pipeline, %s\n", err.message);
             break;

           case MessageType.EOS:

             /*Sending Eos Signal */
             Eos ();
             break;

           case MessageType.STATE_CHANGED:

             Gst.State oldstate;
             Gst.State newstate;
             Gst.State pending;

             string src = ((Element) message.src).get_name ();
             message.parse_state_changed (out oldstate, out newstate,
                 out pending);
             if (debug)
               stderr.printf ("Gstd: %s,changes state from %s to %s\n", src,
                   oldstate.to_string (), newstate.to_string ());

             /*Sending StateChanged Signal */
             StateChanged (oldstate.to_string (), newstate.to_string (), src);
             break;

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
         if (current != state) {
           if (debug)
             stderr.printf ("Gstd: Element, failed to change state %s\n",
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
           stdout.printf ("Gstd: Asynchronous state change to:playing\n");
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
           stdout.printf ("Gstd: Asynchronous state change to:pause\n");
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
           stdout.printf ("Gstd: Asynchronous state change to:null\n");
       }

    /**
     Sets a boolean property for an element on the pipeline
     @param element, whose property needs to be set
     @param property,property name
     @param val, bool property value
     */
       public bool ElementSetPropertyBoolean (string element,
           string property, bool val)
       {
         Gst.Element e;
         Gst.Pipeline pipe;
         GLib.ParamSpec spec;

         pipe = pipeline as Gst.Pipeline;
         e = pipe.get_child_by_name (element) as Element;
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
           return false;
         }

         spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
       public bool ElementSetPropertyInt (string element,
           string property, int val)
       {
         Element e;
         Gst.Pipeline pipe;
         GLib.ParamSpec spec;

         pipe = pipeline as Gst.Pipeline;
         e = pipe.get_child_by_name (element) as Element;
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline\n",
                 element);
           return false;
         }

         spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
       public bool ElementSetPropertyInt64 (string element,
           string property, int64 val)
       {
         Element e;
         Gst.Pipeline pipe;
         GLib.ParamSpec spec;

         pipe = pipeline as Gst.Pipeline;
         e = pipe.get_child_by_name (element) as Element;
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
           return false;
         }

         spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
       public bool ElementSetPropertyString (string element,
           string property, string val)
       {
         Element e;
         Gst.Pipeline pipe;
         GLib.ParamSpec spec;

         pipe = pipeline as Gst.Pipeline;
         e = pipe.get_child_by_name (element) as Element;
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
           return false;
         }

         spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
		   return false;
         }

         GLib.ParamSpec spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
           return false;
         }

         GLib.ParamSpec spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
           return false;
         }

         GLib.ParamSpec spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
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
       public bool ElementGetPropertyString (string element,
           string property, out string val)
       {
         val = "";

         Gst.Pipeline pipe = pipeline as Gst.Pipeline;
         Element e = pipe.get_child_by_name (element) as Element;
         if (e == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s not found on pipeline", element);
           return false;
         }

         GLib.ParamSpec spec = e.get_class ().find_property (property);
         if (spec == null) {
           if (debug)
             stderr.printf ("Gstd: Element %s does not have the property %s\n",
                 element, property);
           return false;
         }

         e.get (property, &val, null);
         return true;
       }

    /**
     Query duration to a pipeline on the server
     @return time in milliseconds or null if not available
    */
       public int PipelineGetDuration ()
       {

         Format format = Gst.Format.TIME;
         int64 duration = 0;
         int idur = -1;

         /* Query duration */
         if (!pipeline.query_duration (ref format, out duration)) {
           return idur;
         }

         if (duration == Gst.CLOCK_TIME_NONE)
           return idur;

         idur = (int) (duration / MSECOND);
         if (debug) {
           stdout.printf ("Gstd: Duration at server is %u:%02u:%02u.%03u\n",
             (uint) (duration / (SECOND * 60 * 60)),
             (uint) ((duration / (SECOND * 60)) % 60),
             (uint) ((duration / SECOND) % 60),
             (uint) (duration % SECOND));
        }
         return idur;
       }

    /**
     Query position to a pipeline on the server
     @return position in milliseconds or null if not available
    */
       public int PipelineGetPosition ()
       {

         Format format = Gst.Format.TIME;
         int64 position = 0;
         int ipos = 0;

         if (!pipeline.query_position (ref format, out position)) {
           return -1;
         }

         if (position == Gst.CLOCK_TIME_NONE)
           return -1;

         ipos = (int) (position / 1000000);
         if (debug) {
             stdout.printf ("Gstd: Position at server is %u:%02u:%02u.%03u\n",
             (uint) (position / (SECOND * 60 * 60)),
             (uint) ((position / (SECOND * 60)) % 60),
             (uint) ((position / SECOND) % 60),
             (uint) (position % SECOND));
         }
         return ipos;
       }

    /**
     Seeks a specific time position.
     Data in the pipeline is flushed.
     @param ipos_ms, absolute position in milliseconds
    */
       public bool PipelineSeek (int ipos_ms)
       {

         Gst.Format format = Gst.Format.TIME;
         Gst.SeekFlags flag = Gst.SeekFlags.FLUSH;
         Gst.SeekType cur_type = Gst.SeekType.SET;
         Gst.SeekType stp_type = Gst.SeekType.NONE;
         int64 stp_pos_ns = CLOCK_TIME_NONE;
         int64 cur_pos_ns = 0;

         /*Converts the current position, which
            is in milliseconds to nanoseconds */
         cur_pos_ns = (int64) (ipos_ms * MSECOND);

         /*Set the current position */
         if (!pipeline.seek (rate, format, flag, cur_type, cur_pos_ns, stp_type,
                 stp_pos_ns)) {
           if (debug) {
             stdout.printf ("Gstd: Media type not seekable\n");
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
       public void PipelineSeekAsync (int ipos_ms)
       {
		   PipelineSeek(ipos_ms);
	   }

    /**
     Skips time, it moves position forward and backwards from
     the current position.
     Data in the pipeline is flushed.
     @param period_ms, relative time in milliseconds
    */
       public bool PipelineSkip (int period_ms)
       {

         Gst.Format format = Gst.Format.TIME;
         Gst.SeekFlags flag = Gst.SeekFlags.FLUSH;
         Gst.SeekType cur_type = Gst.SeekType.SET;
         Gst.SeekType stp_type = Gst.SeekType.NONE;
         int64 stp_pos_ns = CLOCK_TIME_NONE;
         int64 cur_pos_ns = 0;
         int64 seek_ns = 0;

         /*Gets the current position */
         if (!pipeline.query_position (ref format, out cur_pos_ns)) {
           return false;
         }

         /*Sets the new position relative to the current one */
         seek_ns = cur_pos_ns + (int64) (period_ms * MSECOND);

         /*Set the current position */
         if (!pipeline.seek (rate, format, flag, cur_type, seek_ns, stp_type,
                 stp_pos_ns)) {
           if (debug) {
             stdout.printf ("Gstd: Media type not seekable\n");
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
         if (!pipeline.seek (rate, format, flag, type, pos_ns, type, pos_ns)) {
           if (debug) {
             stdout.printf ("Gstd: Speed could not be changed\n");
             return false;
           }
         }
         return true;
       }

     }
