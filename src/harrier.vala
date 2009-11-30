using Gst;
using GLib.List;

[DBus (name = "com.ti.sdo.HarrierInterface")]
public class Harrier : GLib.Object {
    /* Private data */
    private HashTable pipelines;
    private int next_id;

    /**
     Create a new instance of a harrier server 
     */
    public Harrier(){
        pipelines =  new HashTable<int,Pipeline> (int_hash,int_equal);
        next_id = 0;
    }
    
    /**
     Creates a pipeline from a gst-launch like descrition
     @param description, gst-launch like description of the pipeline
     @return integer identifier for the pipeline, -1 on failure
     */
    public int CreatePipeline(string description){
        int ret = -1;

        try {
            /* Create the pipe */
            Element newpipe = parse_launch(description) as Element;
            assert(newpipe != null);
            /* Increase the ref count or the object will be destroyed 
               when the function is done. */
            newpipe.ref_count++;
            
            /* Store the pipe */
//            while (pipelines.lookup(&next_id) != null){
//                next_id++;
//            }
            pipelines.insert(&next_id,newpipe);
            next_id++;
            ret = next_id;
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
    public bool DestroyPipeline(int id){
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
     @see CreatePipeline
    */
    public bool PipelinePlay(int id){
        return PipelineSetState(id,State.PLAYING);
    }
    
    /**
     Sets a pipeline to paused state. Returns when the pipeline already reached
     that state.
     @param id, the integer that identifies the pipe.
     @see CreatePipeline
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
     @see CreatePipeline
    */
    public bool PipelineNull(int id){
        return PipelineSetState(id,State.NULL);
    }
}