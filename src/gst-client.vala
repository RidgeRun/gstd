using GLib;

public class HarrierCli : GLib.Object {

    private DBus.Connection conn;
    private dynamic DBus.Object factory;

    /**
    * Used as reference in option parser
    */
    static string obj_path;
    static bool _signals = false;
    static bool _debug = false;
    [CCode (array_length = false, array_null_terminated = true)]
    static string[] _remaining_args;

    /**
    * Application command line options
    */
    const OptionEntry[] options = {

    { "by_path", 'p', 0, OptionArg.STRING, ref obj_path,
    "Pipeline path, for which command will be apply.Usage:-p <path>", null },

    { "enable_signals", 's', 0, OptionArg.INT, ref _signals,
    "Flag to enable the signals reception.Usage:-s <1>", null },
    
    { "debug", 'd', 0, OptionArg.INT, ref _debug,
    "Flag to enable debug information on a pipeline,useful just for 'create' command.Usage:-d <1>",
    null },

    { "", '\0', 0, OptionArg.FILENAME_ARRAY, ref _remaining_args,
     null, N_("[COMMANDS...]") },

    { null }
    }; 


    /* Command descriptions for the help
       Each description is: name of the command, syntax, description
     */
    private string[,] cmds = {
        {"create","create <\"gst-launch like pipeline description in quotes\">",
         "Creates a new pipeline and returns the dbus-path to access it"},
        {"destroy","-p <path> destroy","Destroys the pipeline specified by_path(-p)"},
        {"play","-p <path> play","Sets the pipeline specified by_path(-p) to play state"},
        {"pause","-p <path> pause","Sets the pipeline specified by_path(-p) to pause state"},
        {"null","-p <path> null","Sets the pipeline specified by_path(-p) to null state"},
        {"set","-p <path> set <element_name> <property_name> <data-type> <value>",
         "Sets an element's property value of the pipeline(option -p needed)"},
        {"get","-p <path> get <element_name> <property_name> <data_type>",
         "Gets an element's property value of the pipeline(option -p needed)"},
        {"get-duration","-p <path> get-duration","Gets the pipeline duration time(option -p needed)"},
        {"get-position","-p <path> get-position","Gets the pipeline position(option -p needed)"}
    };

    /*
    * Constructor
    */
    public HarrierCli() throws DBus.Error, GLib.Error {

        /*Getting a Gstd Factory proxy object*/
        conn = DBus.Bus.get (DBus.BusType.SYSTEM);
        factory = conn.get_object ("com.ridgerun.gstreamer.gstd",
                                   "/com/ridgerun/gstreamer/gstd/factory",
                                   "com.ridgerun.gstreamer.gstd.FactoryInterface");
    }

    /**
    *Callback Functions for the receiving signals
    */

    public void Error_cb(){
        stdout.printf ("Error signal received\n");
    }

    public void Eos_cb(){
        stdout.printf ("End of Stream signal received\n");

    }

    public void StateChanged_cb(){
        stdout.printf ("StateChanged signal received\n");
    }


    /**
    * Console Commands Functions
    */

    private bool pipeline_create(string description){

        string new_objpath = factory.CreateWithDebug(description,_debug);

        if (new_objpath == "") {
            stderr.printf("Failed to create pipeline\n");
            return false;
        }

        stdout.printf("Pipeline path created: %s\n", new_objpath);

        return true;
    }

    private bool pipeline_play(dynamic DBus.Object pipeline){

        bool ret = pipeline.PipelinePlay();
        if (!ret){
            stdout.printf("Failed to put the pipeline to play\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_pause(dynamic DBus.Object pipeline){

        bool ret = pipeline.PipelinePause();
        if (!ret){
            stdout.printf("Failed to put the pipeline to pause\n");
            return false;
        }

        return ret;
    }

    private bool pipeline_null(dynamic DBus.Object pipeline){

        bool ret = pipeline.PipelineNull();
        if (!ret){
            stderr.printf("Failed to put the pipeline to null\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_destroy(string obj_path){

        bool ret = factory.Destroy(obj_path);
        if (!ret){
            stderr.printf("Failed to put the pipeline to null\n");
            return false;
        }
        stdout.printf("Pipeline with path:%s, destroyed\n", obj_path);
        return true;
    }

    private bool pipeline_get_property(dynamic DBus.Object pipeline, string[] args){

        bool ret = true;
        string element = args[1];
        string property = args[2];

        switch (args[3].down()){
        case "boolean":
                bool boolean_v = pipeline.ElementGetPropertyBoolean(element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %s\n",
                               property,element,boolean_v?"true":"false");
                break;
        case "integer":
                int integer_v = pipeline.ElementGetPropertyInt(element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %d\n",
                               property,element,integer_v);
                if (integer_v == -1) ret = false;
                break;
        case "long":
                long long_v = pipeline.ElementGetPropertyLong(element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %ld\n",
                               property,element,long_v);
                if (long_v == -1) ret = false;
                break;
        case "string":
                string string_v = pipeline.ElementGetPropertyString(element,property);
                stdout.printf(">>The '%s' value on element '%s' is: %s\n",
                               property,element,string_v);
                if (string_v == "") ret = false;
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

    private bool pipeline_set_property(dynamic DBus.Object pipeline, string[] args){

        bool ret;
        string element = args[1];
        string property = args[2];

        switch (args[3].down()){
        case "boolean":
                bool boolean_v = args[4].down().to_bool();
                stdout.printf("Trying to set '%s' on element '%s' to %s\n",
                    property,element,boolean_v?"true":"false");
                ret = pipeline.ElementSetPropertyBoolean(element,property,boolean_v);
                break;
        case "integer":
                int integer_v = args[4].to_int();
                stdout.printf("Trying to set '%s' on element '%s' to %d\n",
                    property,element,integer_v);
                ret = pipeline.ElementSetPropertyInt(element,property,integer_v);
                break;
        case "long":
                long long_v = args[4].to_long();
                stdout.printf("Trying to set '%s' on element '%s' to %ld\n",
                    property,element,long_v);
                ret = pipeline.ElementSetPropertyLong(element,property,long_v);
                break;
        case "string":
                string string_v = args[4];
                stdout.printf("Trying to set '%s' on element '%s' to %s\n",
                    property,element,string_v);
                ret = pipeline.ElementSetPropertyString(element,property,string_v);
                break;
        default:
                stderr.printf("Datatype not supported: %s\n",args[4]);
                return false;
        }

        if (!ret){
            stderr.printf("Failed to set property\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_get_duration(dynamic DBus.Object pipeline){

        int time = pipeline.PipelineGetDuration();
        if (time<0){
            stderr.printf("Failed to get pipeline duration\n");
            return false;
        }

        stdout.printf(">>The duration on pipeline is %d, FORMAT need to be fix \n",time);
        return true;
    }

    private bool pipeline_get_position(dynamic DBus.Object pipeline){

        int pos = pipeline.PipelineGetPosition();
        if (pos<0){
            stderr.printf("Failed to get position the pipeline to null\n");
            return false;
        }

        stdout.printf(">>The position on pipeline is: %d, FORMAT need to be fix\n",pos);
        return true;
    }

    public bool parse_cmd(string[] args) throws DBus.Error, GLib.Error {

        dynamic DBus.Object pipeline = null;

        if(obj_path != null){
            pipeline = conn.get_object ("com.ridgerun.gstreamer.gstd",
                                         obj_path,
                                         "com.ridgerun.gstreamer.gstd.PipelineInterface");

            try{
                bool ret=pipeline.PipelineIsInitialized();
                if(!ret){
                    stderr.printf("Pipeline with path:%s, was not initialiazed\n",obj_path);
                    return false;
                }
            } catch (Error e) {
                stderr.printf ("Pipeline with path:%s, has not been created\n",obj_path);
                return false;
            }

        }else if (args[0].down() != "create" && args[0].down() != "help"){
            stderr.printf("Pipeline path was not specified\n");
            return false;
        }

        /*Activating the reception of signals sent by the daemon*/
        /*Need to be FIXED*/
        if(_signals){
            if(args[0].down() != "create" && args[0].down() != "help"){
                stdout.printf("Signals, activated\n");
                pipeline.Error += this.Error_cb;
                pipeline.Eos += this.Eos_cb;
                pipeline.StateChanged += this.StateChanged_cb;
            }
        }

        switch (args[0].down()){

        case "create":
            return pipeline_create(args[1]);

        case "destroy":
            return pipeline_destroy(obj_path);

        case "play":
            return pipeline_play(pipeline);

        case "pause":
            return pipeline_pause(pipeline);

        case "null":
            return pipeline_null(pipeline);

        case "set":
            return pipeline_set_property(pipeline,args);

        case "get":
            return pipeline_get_property(pipeline,args);

        case "get-duration":
            return pipeline_get_duration(pipeline);

        case "get-position":
            return pipeline_get_position(pipeline);

        case "help":
            int id=0;
            if (args.length > 1) {
                /* Help about some command */
                while(cmds[id,0]!=null) {
                    if (cmds[id,0] == args[1]){
                        stdout.printf("Command: %s\n",args[1]);
                        stdout.printf("Description: %s\n",cmds[id,2]);
                        stdout.printf("Syntax: %s\n",cmds[id,1]);
                        return true;
                    }
                    id++;
                }
                stdout.printf("Unknown command: %s\n",args[1]);
                return false;
            } else {
                /* List of commands */
                stdout.printf("Request the syntax of an specific command with "+
                 "\"help <command>\".\n" +
                 "This is the list of supported commands:\n");
                while(cmds[id,0]!=null){
                    stdout.printf(" %s:\t%s\n",cmds[id,0],cmds[id,2]);
                    id++;
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
        stdout.printf("CLI mode not implement yet\n");
        return false;
    }

    public bool parse(string[] args) throws DBus.Error, GLib.Error {
            if (args.length > 0) {
                return parse_cmd(args);
            } else {
                return cli(args);
            }

    }

    static int main (string[] args) {
        HarrierCli cli;

        try {
            obj_path = null;
            var opt = new OptionContext("(For Commands HELP: 'gst-client help')");
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