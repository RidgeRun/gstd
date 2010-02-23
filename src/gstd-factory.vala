using Gst;
using DBus;

[DBus (name = "com.ridgerun.gstreamer.gstd.FactoryInterface")]

     public class Factory:GLib.Object
     {
       private int next_id;
       private Pipeline[] pipes;

    /**
     Create a new instance of a factory server to process D-Bus 
     factory messages
     */
       public Factory ()
       {
         next_id = 0;
         pipes = new Pipeline[20];
         for (int ids = 0; ids < 20; ids++)
         {
           pipes[ids] = null;
         }
       }

    /**
     Creates a pipeline from a gst-launch like description using or not
     debug information
     @param description, gst-launch like description of the pipeline
     @param debug, flag to enable debug information
     @return the dbus-path of the pipeline, or null if out of resources
     */
       public string ? Create (string description, bool debug)
       {
         /* Create our pipeline */
         int starting_id = next_id;
         while (pipes[next_id] != null) {
           next_id = next_id++ % 20;
           if (next_id == starting_id) {
             return null;
           }
         }
         pipes[next_id] = new Pipeline (description, debug);

         if (pipes[next_id].PipelineIsInitialized ()) {
           string objectpath =
               "/com/ridgerun/gstreamer/gstd/pipe" + next_id.to_string ();
           conn.register_object (objectpath, pipes[next_id]);
           pipes[next_id].PipelineSetPath (objectpath);
           next_id++ % 20;
           return objectpath;
         }
         return null;
       }

    /**
     Destroy a pipeline
     @param id, the pipeline id assigned when created
     @return true, if succeded
     @see PipelineId
     */
       public bool Destroy (string objectpath)
       {
         for (int index = 0; index < 20; index++) {
           if (pipes[index].PipelineGetPath () == objectpath) {
             pipes[index] = null;
             return true;
           }
         }

         stderr.printf ("Fail to destroy pipeline\n");
         return false;
       }

    /**
     List the existing pipelines
     @return pipe_list with the corresponding paths
     */
       public string List ()
       {
         int counter = 0;
         string[]pipelist = new string[20];
         string paths = "";

         for (int index = 0; index < 20; index++) {
           if (pipes[index] != null) {
             pipelist[counter] = pipes[index].PipelineGetPath ();
             counter++;
           }
         }
         paths = string.joinv (",", pipelist);
         return paths;

       }

    /**
     Ping Gstd daemon.
     Some GStreamer elements use exit(), thus killing the daemon.
     @return true if alive
     */
       public bool Ping ()
       {
         /*Gstd received the Ping method call */
         return true;
       }
     }
