using Gst;

[DBus (name = "com.ti.sdo.HarrierInterface", signals = "EOS",
	signals = "StateChanged" , signals = "Error")]

public class Harrier : GLib.Object {
    /* Private constants */
    //private static const int MAX_AVAIL_IDS = 20;

    /* Private data */
    private HashTable pipelines;
    private int next_id;
    private int ids_available;
    private int[] ids;
    
    public signal void Eos(/*int id*/);
    public signal void StateChanged(/*int id,*/string new_state);
    public signal void Error(/*int id,*/ string err_message);

    /**
     Create a new instance of a harrier server 
     */
    public Harrier(){
        int i;
        
        pipelines = new HashTable<int,Pipeline> (int_hash,int_equal);
        next_id = 0;
        ids = new int[20];
        ids_available = 20;
        for (i = 0; i < 20; i++){
            ids[i] = i;
        }
    }


    private bool bus_callback (Gst.Bus bus, Gst.Message message) {

        switch (message.type) {
        case MessageType.ERROR:

            GLib.Error err;
            string debug;

            /*Parse error*/
            message.parse_error (out err, out debug);

            /*Sending Error Signal*/
            Error(err.message);
            
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
            StateChanged (newstate.to_string());

            break;

        default:
            break;
        }

        return true;
    }
    
    /**
     Creates a pipeline from a gst-launch like descrition
     @param description, gst-launch like description of the pipeline
     @return integer identifier for the pipeline, -1 on failure
     */
    public int PipelineCreate(string description){
        int ret = -1;

        if (ids_available <= 0){
            stderr.printf("Failed to create pipeline, no more ids available");
            return -1;
        }

        try {
            /* Create the pipe */
            Element newpipe = parse_launch(description) as Element;
            assert(newpipe != null);

            /*Get and watch bus*/
            Bus bus = newpipe.get_bus ();
            bus.add_watch (bus_callback);

            /* Increase the ref count or the object will be destroyed 
               when the function is done. */
            newpipe.ref_count++;

            /* Store the pipe */
            while (pipelines.lookup(&next_id) != null){
                next_id = next_id++ % 20;
            }
            pipelines.insert(&(ids[next_id]),newpipe);
            ret = next_id;
            next_id++;
            ids_available--;
            stdout.printf("Pipeline %d created: %s\n",ret,description);
        } catch (GLib.Error e) {
            stderr.printf("Failed to create pipeline with description: %s.\n" +
                "Error: %s\n",description,e.message);
        }
        
        return ret;
    }

    /**
     Destroys a pipeline on the server
     @param id, the integer that identifies the pipe.
     @see CreatePipeline
    */
    public bool PipelineDestroy(int id){
        GLib.Object *o;
        Element pipe = pipelines.lookup(&id) as Element;

        if (pipe == null) {
            stdout.printf("Pipe not found by id %d\n",id);
            return false;
        }
        
        /* Destroy the pipeline */
        if (!PipelineSetState(id,State.NULL))
            return false;

        /* Remove from the hash */
        pipelines.remove(&id);
        
        /* Release our reference */        
        o = (GLib.Object)pipe;
        delete o;
     
        return true;
    }

    private bool PipelineSetState(int id, State state){
        Element pipe = pipelines.lookup(&id) as Element;
        State current, pending;
        
        if (pipe == null){
            stdout.printf("Pipe not found by id %d\n",id);
            return false;
        }
        pipe.set_state(state);
        /* Wait for the transition at most 2 secs */
        pipe.get_state(out current,out pending, 2000000000);
        if (current != state) {
            stderr.printf("Element %d, failed to change state %s\n",id,
                state.to_string());
            return false;
        }
     
        return true;
    }
    
    /**
     Sets a pipeline to play state. Returns when the pipeline already reached
     that state.
     @param id, the integer that identifies the pipe.
     @see PipelineCreate
    */
    public bool PipelinePlay(int id){
        return PipelineSetState(id,State.PLAYING);
    }
    
    /**
     Sets a pipeline to paused state. Returns when the pipeline already reached
     that state.
     @param id, the integer that identifies the pipe.
     @see PipelineCreate
    */
    public bool PipelinePause(int id){
        return PipelineSetState(id,State.PAUSED);
    }

    /**
     Sets a pipeline to null state. Returns when the pipeline already reached
     that state.
     On this state the pipeline releases all allocated resources, but can
     be reused again.
     @param id, the integer that identifies the pipe.
     @see PipelineCreate
    */
    public bool PipelineNull(int id){
        return PipelineSetState(id,State.NULL);
    }

    /**
     Sets a boolean property for an element on the pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property needs to be set
     @param property,property name
     @param val, bool property value
     @see PipelineCreate
     */
    public bool ElementSetPropertyBoolean(int id, string element,
        string property, bool val){
        Element e;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
            return false;
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
            return false;
        }

        e.set(property,val,null);

        return true;
    }

    /**
     Sets an int property for an element on the pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property needs to be set
     @param property,property name
     @param val, int property value
     @see PipelineCreate
     */
    public bool ElementSetPropertyInt(int id, string element,
        string property, int val){
        Element e;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
            return false;
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d\n",element,id);
            return false;
        }

        e.set(property,val,null);

        return true;
    }
    
    /**
     Sets an long property for an element on the pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property needs to be set
     @param property,property name
     @param val, long property value
     @see PipelineCreate
     */
    public bool ElementSetPropertyLong(int id, string element,
        string property, long val){
        Element e;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
            return false;
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
            return false;
        }

        e.set(property,val,null);

        return true;
    }

    /**
     Sets a string property for an element on the pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property needs to be set
     @param property,property name
     @param val,string property value
     @see PipelineCreate
     */
    public bool ElementSetPropertyString(int id, string element,
        string property, string val){
        Element e;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
            return false;
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
            return false;
        }

        e.set(property,val,null);

        return true;
    }
    
    /**
     Gets an element's bool property value of a specific pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property value wants to be known
     @param property,property name
     @see PipelineCreate
     */
    public bool ElementGetPropertyBoolean(int id, string element,
        string property){
        Element e;
        bool bool_v = false;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
        }

        e.get(property,&bool_v,null);

        return bool_v;
    }

    /**
     Gets an element's int property value of a specific pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property value wants to be known
     @param property,property name
     @see PipelineCreate
     */
    public int ElementGetPropertyInt(int id, string element,
        string property){
        Element e;
        int integer_v = -1;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
        }

        e.get(property,&integer_v,null);

        return integer_v;
    }
    
    /**
     Gets an element's long property value of a specific pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property value wants to be known
     @param property,property name
     @see PipelineCreate
     */
    public long ElementGetPropertyLong(int id, string element,
        string property){
        Element e;
        long long_v = -1;
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
        }

        e.get(property,&long_v,null);

        return long_v;
    }

    /**
     Gets an element's string property value of a specific pipeline
     @param id, the integer that identifies the pipe
     @param element, whose property value wants to be known
     @param property,property name
     @see PipelineCreate
     */
    public string ElementGetPropertyString(int id, string element,
        string property){
        Element e;
        string string_v = "";
        Pipeline pipe = pipelines.lookup(&id) as Pipeline;

        if (pipe == null){
            stderr.printf("Pipe not found by id %d\n",id);
        }

        e = pipe.get_child_by_name(element) as Element;
        if (e == null){
            stderr.printf("Element %s not found on pipe id %d",element,id);
        }

        e.get(property,&string_v,null);

        return string_v;
    }


}