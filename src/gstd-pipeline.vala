using Gst;

[DBus (name = "com.ridgerun.gstreamer.gstd.PipelineInterface", signals = "EOS",
	signals = "StateChanged" , signals = "Error")]

public class Pipeline : GLib.Object {

    /* Private data */
    private Gst.Element pipeline;


    public signal void Eos();
    public signal void StateChanged();
    public signal void Error();

    /**
     Create a new instance of a Pipeline 
     */
    public Pipeline(string description){

        try{
            /* Create the pipe */
            pipeline = parse_launch(description) as Element;
            assert(pipeline != null);

            /*Get and watch bus*/
            Bus bus = pipeline.get_bus ();
            bus.add_watch (bus_callback);

            /* Increase the ref count or the object will be destroyed 
               when the function is done. */
            pipeline.ref_count++;

            stdout.printf("Pipeline created: %s\n",description);

        } catch (GLib.Error e) {
            stderr.printf("Failed to create pipeline with description: %s.\n" +
                "Error: %s\n",description,e.message);
        }
    }


    /**
     Destroy a instance of a Pipeline 
     */
    ~Pipeline(){
        GLib.Object *o;

        /* Destroy the pipeline */
        if (!PipelineSetState(State.NULL))
            stderr.printf("Failed to destroy pipeline\n");
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {

        switch (message.type) {
        case MessageType.ERROR:

            GLib.Error err;
            string debug;

            /*Parse error*/
            message.parse_error (out err, out debug);

            /*Sending Error Signal*/
            /*Need TODO: Review if err.message can be sent*/
            Error(/*err.message*/);

            /*Finish main loop*/
            loop.quit ();
            break;

        case MessageType.EOS:

            /*Sending Eos Signal*/
            Eos();
            break;

        case MessageType.STATE_CHANGED:

            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;

            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            
            /*Sending StateChanged Signal*/
            StateChanged (/*newstate.to_string()*/);

            break;

        default:
            break;
        }

        return true;
    }

    private bool PipelineSetState(State state){

        State current, pending;

        pipeline.set_state(state);
        /* Wait for the transition at most 2 secs */
        pipeline.get_state(out current,out pending, 2000000000);
        if (current != state) {
            stderr.printf("Element, failed to change state %s\n",
                state.to_string());
            return false;
        }
        return true;
    }

    /**
     Sets a pipeline to play state. Returns when the pipeline already reached
     that state.
    */
    public bool PipelinePlay(){
        return PipelineSetState(State.PLAYING);
    }

    /**
     Sets a pipeline to paused state. Returns when the pipeline already reached
     that state.
    */
    public bool PipelinePause(){
        return PipelineSetState(State.PAUSED);
    }

    /**
     Sets a pipeline to null state. Returns when the pipeline already reached
     that state.
     On this state the pipeline releases all allocated resources, but can
     be reused again.
    */
    public bool PipelineNull(){
        return PipelineSetState(State.NULL);
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
            stderr.printf("Element %s not found on pipeline",element);
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
            stderr.printf("Element %s not found on pipeline\n",element);
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
            stderr.printf("Element %s not found on pipeline",element);
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
            stderr.printf("Element %s not found on pipeline",element);
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
            stderr.printf("Element %s not found on pipeline",element);
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
            stderr.printf("Element %s not found on pipeline",element);
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
            stderr.printf("Element %s not found on pipeline",element);
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
            stderr.printf("Element %s not found on pipeline",element);
        }

        e.get(property,&string_v,null);

        return string_v;
    }

    /**
     Query duration to a pipeline on the server
    */
    public int64 PipelineGetDuration(){

        Format format = Gst.Format.TIME;
        int64 duration;


        /* Query duration */
        if (! pipeline.query_duration (ref format, out duration)){
            stdout.printf("Unable to get duration to pipe\n");
            return -1;
        }

        return duration;
    }
    
    /**
     Query position to a pipeline on the server
    */
    public int64 PipelineGetPosition(){

        Format format = Gst.Format.TIME;
        int64 position;

        /* Query position */
        if (! pipeline.query_position (ref format, out position)){
            stdout.printf("Unable to get position to pipe\n");
            return -1;
        }

        return position;
    }

}