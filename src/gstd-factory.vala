/*
 * gstd/src/gstd-factory.vala
 *
 * GStreamer daemon pipeline Factory class - framework for controlling audio and video streaming using D-Bus messages
 *
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
 *
 * GPL2 license - See http://www.opensource.org/licenses/gpl-2.0.php for complete text.
*/using Gst;

using DBus;

[DBus (name = "com.ridgerun.gstreamer.gstd.FactoryInterface", signals = "Alive")]

     public class Factory:GLib.Object
     {
       private Pipeline[] pipes;
       private const int num_pipes = 20;
       private TimeoutSource timer = null;
       private uint _txCounter = 0;
       private uint _rxCounter = 0;

    /**
     Create a new instance of a factory server to process D-Bus 
     factory messages
     */
       public Factory ()
       {
         pipes = new Pipeline[num_pipes];
         for (int ids = 0; ids < pipes.length; ids++)
         {
           pipes[ids] = null;
         }

         //signal alive every second
         timer = new TimeoutSource(1000);
         timer.set_callback(() => {
           CheckAlive();
           return true;
         });
         timer.attach(loop.get_context());
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
         int next_id = 0;
         while (pipes[next_id] != null) {
           next_id = (next_id + 1) % 20;
           if (next_id == 0) {
             return "";
           }
         }
         pipes[next_id] = new Pipeline (description, debug);

         if (!pipes[next_id].PipelineIsInitialized ()) {
           pipes [next_id] = null;
           return "";
         }
         string objectpath =
             "/com/ridgerun/gstreamer/gstd/pipe" + next_id.to_string ();
         conn.register_object (objectpath, pipes[next_id]);
         pipes[next_id].PipelineSetPath (objectpath);
         return objectpath;
       }

    /**
     Destroy a pipeline
     @param id, the pipeline id assigned when created
     @return true, if succeded
     @see PipelineId
     */
       public bool Destroy (string objectpath)
       {
         for (int index = 0; index < pipes.length; index++) {
           if (pipes[index] != null) {
             if (pipes[index].PipelineGetPath () == objectpath) {
               pipes[index] = null;
               return true;
             }
           }
         }

         Posix.syslog (Posix.LOG_ERR, "Fail to destroy pipeline");
         return false;
       }

    /**
     List the existing pipelines
     @return pipe_list with the corresponding paths
     */
       public string[] List ()
       {
         string[] paths = {};

         for (int index = 0; index < pipes.length; ++index) {
           if (pipes[index] != null) {
             paths += pipes[index].PipelineGetPath ();
           }
         }
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

       private void CheckAlive ()
       {
         //increment counter
         ++_txCounter;

         //push event into each pipe
         uint nrOfPipes = 0;
         for (int index = 0; index < pipes.length; ++index) {
           if (pipes[index] == null)
             continue;
           if (!pipes[index].PipelineIsInitialized())
             continue;

           if (pipes[index].GetCounter() == 0) {
             pipes[index].SetCounter(_txCounter);
           }
           else {
             pipes[index].SendNewCounterEvent(_txCounter);
           }
           ++nrOfPipes;
         }

         //no pipe, no cry
         if (nrOfPipes == 0) {
           Alive();
           return;
         }

         //find smallest counter
         uint minCounter = _txCounter;
         for (int index = 0; index < pipes.length; ++index) {
           if (pipes[index] == null)
             continue;
           if (!pipes[index].PipelineIsInitialized())
             continue;
           uint counter = pipes[index].GetCounter();
           if (counter < minCounter)
               minCounter = counter;
         }

         if (_rxCounter != minCounter)
         {
           _rxCounter = minCounter;
           Alive();
         }
       }

       public signal void Alive();
     }
