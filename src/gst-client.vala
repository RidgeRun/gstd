using GLib;

public class HarrierCli : GLib.Object {

    private DBus.Connection conn;
    private dynamic DBus.Object harrier;
    private int active_id;

    /**
    * Used as reference in option parser
    */
    static int arg_id;
    static bool _signals;
    [CCode (array_length = false, array_null_terminated = true)]
    [NoArrayLength]
    static string[] _remaining_args;

    /**
    * Application command line options
    */
    const OptionEntry[] options = {

    { "by_id", 'i', 0, OptionArg.INT, ref arg_id,
    "Pipeline ID number, for which command will be apply", null },

    { "enable_signals", 's', 0, OptionArg.INT, ref _signals,
    "Flag to enable the signals reception", null },

    { "", '\0', 0, OptionArg.FILENAME_ARRAY, ref _remaining_args,
     null, N_("[COMMANDS...]") },

    { null }
    }; 


    /* Command descriptions for the help
       Each description is: name of the command, syntax, description
     */
    private string[,] cmds = {
        {"create","create <\"gst-launch like pipeline description in quotes\">",
         "Create a new pipeline and returns the id for it on the servers"},
        {"destroy","destroy","Destroys the active pipeline"},
        {"play  ","play","Sets the active pipeline to play state"},
        {"pause  ","pause","Sets the active pipeline to pause state"},
        {"null  ","null","Sets the active pipeline to null state"},
        {"set ","set <element_name> <property_name> <data-type> <value>",
        "Sets an element's property value of the active pipeline"},
        {"get ","get <element_name> <property_name> <data-type>",
        "Gets an element's property value of the active pipeline"},
        {"get-duration ","get-duration","Gets the active pipeline duration time"},
        {"get-position ","get-position","Gets the active pipeline position"},
        {"--by_id ","-i <pipe_id>","Flag to apply the command to a specific pipeline"}
    };

    /**
    *Callback Functions for the receiving signals
    */

    public void Error_cb(/*dynamic DBus.Object harrier*/){
        stdout.printf("I get in ERROR callback function!!\n");
        //stdout.printf (/*"Error: %s\n", err.message*/);
    }

    public void Eos_cb(/*dynamic DBus.Object harrier*/){
        stdout.printf("I get in EOS callback function!!\n");
        stdout.printf ("end of stream\n");

    }

    static void StateChanged_cb(dynamic DBus.Object harrier,string newstate){
        stdout.printf("I get in StatedChanged callback function!!\n");
        stdout.printf ("state changed to:%s\n", newstate);
    }

    /*
    * Constructor
    */
    public HarrierCli() throws DBus.Error, GLib.Error {
        string env_id;
        conn = DBus.Bus.get (DBus.BusType.SESSION);
        harrier = conn.get_object ("com.ti.sdo.HarrierService",
                                   "/com/ti/sdo/HarrierObject",
                                   "com.ti.sdo.HarrierInterface");
        stdout.printf("Constructing harrier...\n");
        active_id = -1;
        env_id = Environment.get_variable("HARRIER_ACTIVE_ID");
        if (env_id != null){
            active_id = env_id.to_int();
            stdout.printf(
              "NOTICE: Using active id from enviroment variable: %d\n",
              active_id);
        }

        /*Activating the reception of signals sent by the daemon*/
        if(_signals){
                stdout.printf("Signals, activated\n");
                harrier.Error += this.Error_cb;
                harrier.Eos += this.Eos_cb;
                harrier.StateChanged += StateChanged_cb;
                //harrier.StateChanged.connect (StateChanged_cb);
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
        bool ret = harrier.PipelineDestroy(id);
        if (!ret){
            stdout.printf("Failed to destroy the pipeline\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_get_property(int id,string[] args){

        bool ret=true;
        string element = args[1];
        string property = args[2];

        switch (args[3].down()){
        case "boolean":
                bool boolean_v = harrier.ElementGetPropertyBoolean(id,element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %s\n",
                               property,element,boolean_v?"true":"false");
                break;
        case "integer":
                int integer_v = harrier.ElementGetPropertyInt(id,element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %d\n",
                               property,element,integer_v);
                if (integer_v == -1) ret=false;
                break;
        case "long":
                long long_v = harrier.ElementGetPropertyLong(id,element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %ld\n",
                               property,element,long_v);
                if (long_v == -1) ret=false;
                break;
        case "string":
                string string_v = harrier.ElementGetPropertyString(id,element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %s\n",
                               property,element,string_v);
                if (string_v == "") ret=false;
                break;
        default:
                stderr.printf("Datatype not supported: %s\n",args[4]);
                return false;
        }

        if (!ret){
            stdout.printf("Failed to get property\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_set_property(int id,string[] args){

        bool ret;
        string element = args[1];
        string property = args[2];

        switch (args[3].down()){
        case "boolean":
                bool boolean_v = args[4].down().to_bool();
                stdout.printf("Trying to set '%s' on element '%s' to %s\n",
                    property,element,boolean_v?"true":"false");
                ret = harrier.ElementSetPropertyBoolean(id,element,property,boolean_v);
                break;
        case "integer":
                int integer_v = args[4].to_int();
                stdout.printf("Trying to set '%s' on element '%s' to %d\n",
                    property,element,integer_v);
                ret = harrier.ElementSetPropertyInt(id,element,property,integer_v);
                break;
        case "long":
                long long_v = args[4].to_long();
                stdout.printf("Trying to set '%s' on element '%s' to %ld\n",
                    property,element,long_v);
                ret = harrier.ElementSetPropertyLong(id,element,property,long_v);
                break;
        case "string":
                string string_v = args[4];
                stdout.printf("Trying to set '%s' on element '%s' to %s\n",
                    property,element,string_v);
                ret = harrier.ElementSetPropertyString(id,element,property,string_v);
                break;
        default:
                stderr.printf("Datatype not supported: %s\n",args[4]);
                return false;
        }

        if (!ret){
            stdout.printf("Failed to set property\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_get_duration(int id){
        
        int64 time = harrier.PipelineGetDuration(id);
        if (time<0){
            stdout.printf("Failed to get pipeline duration\n");
            return false;
        }

        stdout.printf(">>The duration on pipeline '%d' is: %lld\n",
                               id,(int64)time);
        return true;
    }

    private bool pipeline_get_position(int id){
        
        int64 pos = harrier.PipelineGetPosition(id);
        if (pos<0){
            stdout.printf("Failed to get position the pipeline to null\n");
            return false;
        }

        stdout.printf(">>The position on pipeline '%d' is: %lld\n",
                               id,(int64)pos);
        return true;
    }

    public bool parse_cmd(string[] args) throws DBus.Error, GLib.Error {

        int id = -1;

        if(arg_id != -1){
            id = arg_id;
            stdout.printf("pipeline id: %i\n",id);
        }
        else if (active_id == -1){
                if(args[0].down()!="create"){
                    stdout.printf("No valid active pipeline id\n");
                    return false;
                }
            }
            else id = active_id;

        switch (args[0].down()){

        case "create":
            stdout.printf("Creating pipe: %s\n",args[1]);
            id = harrier.PipelineCreate(args[1]);
                if (id < 0) {
                stdout.printf("Failed to create pipeline");
                return false;
                }
                /* To do, keep a list of ids */
                active_id = id;
                stdout.printf("Active id is now %d\n",active_id);
                break;

        case "destroy":
            return pipeline_destroy(id);

        case "play":
            return pipeline_play(id);

        case "pause":
            return pipeline_pause(id);

        case "null":
            return pipeline_null(id);

        case "set":
            return pipeline_set_property(id,args);

        case "get":
            return pipeline_get_property(id,args);

        case "get-duration":
            return pipeline_get_duration(id);
        
        case "get-position":
            return pipeline_get_position(id);

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
            if (args.length > 0) {
                stdout.printf("Command_parse:%s \n",args[0]);
                return parse_cmd(args);
            } else {
                stdout.printf("Command_cli:%i \n",args.length);
                return cli(args);
            }

    }

    static int main (string[] args) {
        HarrierCli cli;

        try {

            arg_id = -1;
            var opt = new OptionContext("- gst-client");
            opt.set_help_enabled(true);
            opt.add_main_entries(options, null);
            opt.parse(ref args);

            cli = new HarrierCli();

            if (!cli.parse(_remaining_args))
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