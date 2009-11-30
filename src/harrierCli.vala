using GLib;

public class HarrierCli : GLib.Object {
    private DBus.Connection conn;
    private dynamic DBus.Object harrier;
    private int active_id;
    /* Command descriptions for the help
       Each description is: name of the command, syntax, description
     */
    private string[,] cmds = {
        {"create","create <\"gst-launch like pipeline description in quotes\">",
         "Create a new pipeline and returns the id for it on the servers"},
        {"destroy","destroy","Destroys the active pipeline"},
        {"destroy_id","destroy_id <id>",
         "Destroys the pipeline with the specified id"},
        {"play  ","play","Sets the active pipeline to play state"},
        {"play_id","play_id <id>",
         "Sets the pipeline with the specified id to play state"}
    };

    public HarrierCli() throws DBus.Error, GLib.Error {
        string env_id;
        conn = DBus.Bus.get (DBus.BusType.SESSION);
        harrier = conn.get_object ("com.ti.sdo.HarrierService",
                                   "/com/ti/sdo/HarrierObject",
                                   "com.ti.sdo.HarrierInterface");
        active_id = 0;
        env_id = Environment.get_variable("HARRIER_ACTIVE_ID");
        if (env_id != null){
            active_id = env_id.to_int();
            stdout.printf(
              "NOTICE: Using active id from enviroment variable: %d\n",
              active_id);
        }
    }
    
    private bool pipeline_play(int id){
        bool ret = harrier.PipelinePlay(id);
        if (!ret){
            stdout.printf("Failed to put the pipeline to play\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_pause(int id){
        bool ret = harrier.PipelinePause(id);
        if (!ret){
            stdout.printf("Failed to put the pipeline to pause\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_null(int id){
        bool ret = harrier.PipelineNull(id);
        if (!ret){
            stdout.printf("Failed to put the pipeline to null\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_destroy(int id){
        bool ret = harrier.DestroyPipeline(id);
        if (!ret){
            stdout.printf("Failed to destroy the pipeline\n");
            return false;
        }
        return ret;
    }
    
    public bool parse_cmd(string[] args) throws DBus.Error, GLib.Error {
        int id;

        switch (args[1].down()){
        case "create":
            stdout.printf("Creating pipe: %s\n",args[2]);
    	    id = harrier.CreatePipeline(args[2]);
          	if (id < 0) {
                stdout.printf("Failed to create pipeline");
                return false;
           	}
           	/* To do, keep a list of ids */
           	active_id = id;
           	stdout.printf("Active id is now %d\n",active_id);
           	break;
        case "destroy":
            if (active_id == 0){
                stdout.printf("No valid active pipeline id\n");
                return false;
            }
            return pipeline_destroy(active_id);
        case "destroy_id":
            id = args[2].to_int();
            return pipeline_destroy(id);
        case "play":
            if (active_id == 0){
               stdout.printf("No valid active pipeline id\n");
               return false;
            }
            return pipeline_play(active_id);
        case "play_id":
            id = args[2].to_int();
            return pipeline_play(id);
        case "pause":
            if (active_id == 0){
               stdout.printf("No valid active pipeline id\n");
               return false;
            }
            return pipeline_pause(active_id);
        case "pause_id":
            id = args[2].to_int();
            return pipeline_pause(id);
        case "null":
            if (active_id == 0){
               stdout.printf("No valid active pipeline id\n");
               return false;
            }
            return pipeline_null(active_id);
        case "null_id":
            id = args[2].to_int();
            return pipeline_null(id);
        case "help":
            if (args.length > 2) {
                /* Help about some command */
                for (id = 0; id < cmds[0].length -1; id++) {
                    if (cmds[id,0] == args[2]){
                        stdout.printf("Command: %s\n",args[2]);
                        stdout.printf("Description: %s\n",cmds[id,2]);
                        stdout.printf("Syntax: %s\n",cmds[id,1]);
                        return true;
                    }
                }
                stdout.printf("Unknown command: %s\n",args[2]);
                return false;
            } else {
                /* List of commands */
                stdout.printf("Request the syntax of an specific command with "+
                 "\"help <command>\".\n" +
                 "This is the list of supported commands:\n");
                for (id = 0; id < cmds[0].length - 1; id++) {
                    stdout.printf(" %s:\t%s\n",cmds[id,0],cmds[id,2]);
                }
                stdout.printf("\n");
            }
            break;
        default:
            stderr.printf("Unkown command: %s\n",args[1]);
            return false;
        }
            
        return true;
    }

    public bool cli(string[] args) throws DBus.Error, GLib.Error {
/*
        string line;
        string tokens[40];
        Scanner scan = new Scanner(null);
        line = stdin.read_line();
        scan.input_text(line,(uint)line.length);
        Scanner.get_next_token(
  */      
        return false;
    }
    
    public bool parse(string[] args) throws DBus.Error, GLib.Error {
            if (args.length > 1) {
                return parse_cmd(args);
            } else {
                return cli(args);
            }

    }

    static int main (string[] args) {
        HarrierCli cli;
        
        try {
            cli = new HarrierCli();
            
            if (!cli.parse(args))
                return -1;
        } catch (DBus.Error e) {
            stderr.printf ("DBus failure: %s\n",e.message);
            return 1;
        } catch (GLib.Error e) {
            stderr.printf ("Dynamic method failure\n");
            return 1;
        }

        return 0;
    }
}