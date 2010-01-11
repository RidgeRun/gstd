using Gst;

[DBus (name = "com.ridgerun.gstreamer.gstd.FactoryInterface")]

public class Factory : GLib.Object {
    private int next_id;
    private Pipeline[] pipes;

    /**
     Create a new instance of a factory server 
     */
    public Factory(){
        next_id = 0;
        pipes = new Pipeline[20];
        for(int ids=0; ids<20; ids++){
            pipes[ids] = null;
        }
    }

    /**
     Creates a pipeline from a gst-launch like descrition
     @param description, gst-launch like description of the pipeline
     @return the dbus-path of the pipeline
     */
    public string Create(string description){


        /* Create our pipeline*/
        while (pipes[next_id] != null){
            next_id = next_id++ % 20;
        }
        pipes[next_id] = new Pipeline(description);

        if (pipes[next_id].PipelineIsInitialized()){
            string objectpath = "/com/ridgerun/gstreamer/gstd/pipe" + next_id.to_string();
            conn.register_object (objectpath, pipes[next_id]);
            next_id++;
            return objectpath;
        }

        return "";
    }

    public string CreateWithDebug(string description,bool debug){

        if(debug){

            /* Create our pipeline*/
            while (pipes[next_id] != null){
                next_id = next_id++ % 20;
            }
            pipes[next_id] = new Pipeline.withDebug(description,debug);

            if (pipes[next_id].PipelineIsInitialized()){
                string objectpath = "/com/ridgerun/gstreamer/gstd/pipe" + next_id.to_string();
                conn.register_object (objectpath, pipes[next_id]);
                next_id++;
                return objectpath;
            }

            return "";

        }else { 
            string ret = Create(description);
            return ret;
        }
    }

    /**
     Destroy a pipeline from a gst-launch like descrition
     @param objectpath, the dbus-objectpathe of the pipeline
     @return true,if succeded
     */
    public bool Destroy(string objectpath){


        GLib.Object pipeline;
        int id = 0;

        pipeline = conn.lookup_object(objectpath);

        /* Searching our pipeline*/
        while(pipes[id] != pipeline){
            id++;
            if (id == 20){
                stderr.printf("Fail to destroy pipeline:%s\n", objectpath);
                return false;
            }
        }

        pipes[id] = null;
        return true;

    }
}