using Gst;

[DBus (name = "com.ridgerun.gstreamer.gstd.PipelineInterface", signals = "EOS",
        signals = "StateChanged" , signals = "Error")]

public class Pipeline : GLib.Object {

    /* Private data */
    private Gst.Element pipeline;
    private bool debug = false;
    private bool initialized = false;
    private int id = -1;
    private string path = "";

    public signal void Eos();
    public signal void StateChanged(string old_state, string new_state, string src);
    public signal void Error(string err_message);

    /**
     Create a new instance of a Pipeline 
     */
    public Pipeline(string description, int ids){

        try{
            /* Create the pipe */
            pipeline = parse_launch(description) as Element;
            assert(pipeline != null);

            /* Set pipeline state to initialized */
            id=ids;
            initialized = true;

            /*Get and watch bus*/
            Bus bus = pipeline.get_bus ();
            bus.add_watch (bus_callback);

        } catch (GLib.Error e) {
            stderr.printf("Gstd>Error: %s\n",e.message);
        }
    }

    public Pipeline.withDebug(string description,int ids, bool _debug){

        this(description,ids);
        this.debug = _debug;

        if (_debug){
            if(this.PipelineIsInitialized())
                stdout.printf("Gstd>Pipeline created: %s\n",description);
            else
                stderr.printf("Pipeline could not be initialized\n");
        }
    }

    /**
     Destroy a instance of a Pipeline 
     */
    ~Pipeline(){
        /* Destroy the pipeline */
        if (!PipelineSetState(State.NULL))
            stderr.printf("Gstd>Failed to destroy pipeline\n");
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case MessageType.ERROR:

            GLib.Error err;
            string dbg;

            /*Parse error*/
            message.parse_error (out err, out dbg);

            /*Sending Error Signal*/
            Error(err.message);

            if (debug)
                stderr.printf("Gstd>Error on pipeline: %s\n",err.message);
            break;

        case MessageType.EOS:

            /*Sending Eos Signal*/
            Eos();
            break;

        case MessageType.STATE_CHANGED:

            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;

            string src = ((Element)message.src).get_name();
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            if (debug)
                stderr.printf("Gstd>%s:Change state from %s to %s\n",src,
                               oldstate.to_string(),newstate.to_string());

            /*Sending StateChanged Signal*/
            StateChanged (oldstate.to_string(),newstate.to_string(),src);
            break;

        default:
            break;
        }

        return true;
    }

    private bool PipelineSetState(State state){

        State current, pending;

        pipeline.set_state(state);
        /* Wait for the transition at most 8 secs */
        pipeline.get_state(out current,out pending, (Gst.ClockTime)4000000000u);
        pipeline.get_state(out current,out pending, (Gst.ClockTime)4000000000u);
        if (current != state) {
            if (debug)
                stderr.printf("Gstd>Element, failed to change state %s\n",
                state.to_string());
            return false;
        }
        return true;
    }

    /**
     Returns initialized flag value.
    */
    public bool PipelineIsInitialized(){
        return this.initialized;
    }

    /**
     Returns ID value, set when initialized
    */
    public int PipelineId(){
        return this.id;
    }

    /**
     Returns dbus-path,assigned when created
    */
    public string PipelineGetPath(){
        return this.path;
    }

    /**
     Sets a dbus-path,assigned when connected to daemon
    */
    public bool PipelineSetPath(string dbuspath){
        this.path = dbuspath;
        return true;
    }

    /**
     Gets the pipeline state
    */
    public string PipelineGetState(){

        State current, pending;

        pipeline.get_state(out current,out pending, (Gst.ClockTime)2000000000u);
        return current.to_string();
    }

    /**
     Sets a pipeline to play state. Returns when the pipeline has already reached
     that state.
    */
    public bool PipelinePlay(){
        return PipelineSetState(State.PLAYING);
    }

    /**
     Sets a pipeline to play state. Returns immediately
    */
    public bool PipelineAsyncPlay(){
        pipeline.set_state(State.PLAYING);
        if (debug)
                stdout.printf("Gstd>Asynchronous state change to:playing\n");
        return true;
    }

    /**
     Sets a pipeline to paused state. Returns when the pipeline has already reached
     that state.
    */
    public bool PipelinePause(){
        return PipelineSetState(State.PAUSED);
    }

    /**
     Sets a pipeline to paused state. Returns immediately
    */
    public bool PipelineAsyncPause(){
        pipeline.set_state(State.PAUSED);
        if (debug)
                stdout.printf("Gstd>Asynchronous state change to:pause\n");
        return true;
    }

    /**
     Sets a pipeline to null state. Returns when the pipeline has already reached
     that state.
     On this state the pipeline releases all allocated resources, but can
     be reused again.
    */
    public bool PipelineNull(){
        return PipelineSetState(State.NULL);
    }

    /**
     Sets a pipeline to null state. Returns immediately
    */
    public bool PipelineAsyncNull(){
        pipeline.set_state(State.NULL);
        if (debug)
                stdout.printf("Gstd>Asynchronous state change to:null\n");
        return true;
    }

    /**
     Sets a boolean property for an element on the pipeline
     @param element, whose property needs to be set
     @param property,property name
     @param val, bool property value
     */
    public bool ElementSetPropertyBoolean(string element,
        string property, bool val){
        Gst.Element e;
        Gst.Pipeline pipe;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
            return false;
        }

        e.set(property,val,null);

        return true;
    }

    /**
     Sets an int property for an element on the pipeline
     @param element, whose property needs to be set
     @param property,property name
     @param val, int property value
     */
    public bool ElementSetPropertyInt(string element,
        string property, int val){
        Element e;
        Gst.Pipeline pipe;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline\n",element);
            return false;
        }

        e.set(property,val,null);

        return true;
    }

    /**
     Sets an long property for an element on the pipeline
     @param element, whose property needs to be set
     @param property,property name
     @param val, long property value     */
    public bool ElementSetPropertyLong(string element,
        string property, long val){
        Element e;
        Gst.Pipeline pipe;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
            return false;
        }

        e.set(property,val,null);

        return true;
    }

    /**
     Sets a string property for an element on the pipeline
     @param element, whose property needs to be set
     @param property,property name
     @param val,string property value
     */
    public bool ElementSetPropertyString(string element,
        string property, string val){
        Element e;
        Gst.Pipeline pipe;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
            return false;
        }

        e.set(property,val,null);

        return true;
    }
    
    /**
     Gets an element's bool property value of a specific pipeline
     @param element, whose property value wants to be known
     @param property,property name
     */
    public bool ElementGetPropertyBoolean(string element,
        string property){
        Element e;
        Gst.Pipeline pipe;
        bool bool_v = false;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
        }

        e.get(property,&bool_v,null);

        return bool_v;
    }

    /**
     Gets an element's int property value of a specific pipeline
     @param element, whose property value wants to be known
     @param property,property name
     */
    public int ElementGetPropertyInt(string element,
        string property){
        Element e;
        Gst.Pipeline pipe;
        int integer_v = -1;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
        }

        e.get(property,&integer_v,null);

        return integer_v;
    }

    /**
     Gets an element's long property value of a specific pipeline
     @param element, whose property value wants to be known
     @param property,property name
     */
    public long ElementGetPropertyLong(string element,
        string property){
        Element e;
        Gst.Pipeline pipe;
        long long_v = -1;

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
        }

        e.get(property,&long_v,null);

        return long_v;
    }

    /**
     Gets an element's string property value of a specific pipeline
     @param element, whose property value wants to be known
     @param property,property name
     */
    public string ElementGetPropertyString(string element,
        string property){
        Element e;
        Gst.Pipeline pipe;
        string string_v = "";

        pipe = pipeline as Gst.Pipeline;
        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            if(debug)
                stderr.printf("Gstd>Element %s not found on pipeline",element);
        }

        e.get(property,&string_v,null);

        return string_v;
    }

    /**
     Query duration to a pipeline on the server
    */
    public int PipelineGetDuration(){

        Format format = Gst.Format.TIME;
        int64 duration = 0;
        int idur = 0;

        /* Query duration */
        if (! pipeline.query_duration (ref format, out duration)){
            return -1;
        }

        if (duration == Gst.CLOCK_TIME_NONE)
            return -1;

        idur = (int)(duration / 1000000);
        if(debug)
            stdout.printf("Gstd>Duration at server is %d\n",idur);

        return idur;
    }

    /**
     Query position to a pipeline on the server
    */
    public int PipelineGetPosition(){

        Format format = Gst.Format.TIME;
        int64 position = 0;
        int ipos = 0;

        if (! pipeline.query_position (ref format, out position)){
            return -1;
        }

        if (position == Gst.CLOCK_TIME_NONE)
            return -1;

        ipos = (int)(position / 1000000);
        if(debug)
            stdout.printf("Gstd>Position at server is %d\n",ipos);

        return ipos;
    }

}