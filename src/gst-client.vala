using GLib;

///
public class GstdCli : GLib.Object {

    private DBus.Connection conn;
    private dynamic DBus.Object factory;
    private string active_pipe = null;
    private bool cli_enable = false;
    dynamic DBus.Object pipeline = null;

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
        {"destroy","destroy","Destroys the pipeline specified by_path(-p) or the active pipeline"},
        {"play","play","Sets the pipeline specified by_path(-p) or the active pipeline to play state"},
        {"pause","pause","Sets the pipeline specified by_path(-p) or the active pipeline to pause state"},
        {"null","null","Sets the pipeline specified by_path(-p) or active pipeline to null state"},
        {"play-async","play-async","Sets the pipeline to play state, it does not wait to change to be done"},
        {"pause-async","pause-async","Sets the pipeline to pause state, it does not wait to change to be done"},
        {"null-async","null-async","Sets the pipeline to null state, it does not wait to change to be done"},
        {"set","set <element_name> <property_name> <data-type> <value>",
         "Sets an element's property value of the pipeline"},
        {"get","get <element_name> <property_name> <data_type>",
         "Gets an element's property value of the pipeline"},
        {"get-duration","get-duration","Gets the pipeline duration time"},
        {"get-position","get-position","Gets the pipeline position"},
        {"get-state","get-state","Get the state of an specific pipeline(-p option) or the active pipeline"},
        {"list-pipes","list-pipes","Returns a list of all the dbus-path of the existing pipelines"},
        {"ping","ping","Just to see if gstd is alive"},
        {"set-active","set-active <path>","Set active pipeline using the dbus-path returned when the pipeline was created"},
        {"get-active","get-active","Returns the active pipeline dbus-path"},
        {"seek","seek <position[ms]>","Moves current playing position to a new one"},
        {"skip","skip <period[ms]>","Skips a period, if positive: it moves foward, if negative: it moves backward"},
        {"speed","speed <rate>","Changes playback rate, it enables fast-foward or fast-reverse playback"},
        {"quit","quit","Quit active console"}
    };

    /*
    * Constructor
    */
    public GstdCli() throws DBus.Error, GLib.Error {

        /*Getting a Gstd Factory proxy object*/
        conn = DBus.Bus.get (DBus.BusType.SYSTEM);
        factory = conn.get_object ("com.ridgerun.gstreamer.gstd",
                                   "/com/ridgerun/gstreamer/gstd/factory",
                                   "com.ridgerun.gstreamer.gstd.FactoryInterface");
    }

    /**
    *Callback functions for the receiving signals
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

    private bool pipeline_create(string? description){

        if(description == null){
            stderr.printf("Pipeline description between quotes(\"\") needed\n");
            return false;
        }

        string new_objpath = factory.CreateWithDebug(description,_debug);

        if (new_objpath == "") {
            stderr.printf("Failed to create pipeline\n");
            return false;
        }

        /*Set and create the active pipeline
          when interactive console is enabled*/
        if(cli_enable){
            active_pipe = new_objpath;
            create_proxypipe(active_pipe);
        }

        stdout.printf("Pipeline path created: %s\n", new_objpath);
        return true;
    }

    private bool pipeline_destroy(dynamic DBus.Object pipeline){

        /*This needs to be reviewed, casting compiles but does not
          function*/
        int id = pipeline.PipelineId();
        bool ret = factory.Destroy(id);
        if (!ret){
            stderr.printf("Failed to put the pipeline to null\n");
            return false;
        }
        if(cli_enable){
            stdout.printf("The active pipeline:%s,was destroyed\n", active_pipe);
            active_pipe=null;
        }else
            stdout.printf("Pipeline with path:%s, destroyed\n", obj_path);
        return true;
    }

    private bool pipeline_play(dynamic DBus.Object pipeline,bool sync){

        bool ret;

        if (sync)
            ret = pipeline.PipelinePlay();
        else
            ret = pipeline.PipelineAsyncPlay();
        if (!ret){
            stdout.printf("Failed to put the pipeline to play\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_pause(dynamic DBus.Object pipeline,bool sync){

        bool ret;

        if (sync)
            ret = pipeline.PipelinePause();
        else
            ret = pipeline.PipelineAsyncPause();
        if (!ret){
            stdout.printf("Failed to put the pipeline to pause\n");
            return false;
        }

        return ret;
    }

    private bool pipeline_null(dynamic DBus.Object pipeline, bool sync){

        bool ret;

        if (sync)
            ret = pipeline.PipelineNull();
        else
            ret = pipeline.PipelineAsyncNull();
        if (!ret){
            stderr.printf("Failed to put the pipeline to null\n");
            return false;
        }
        return ret;
    }

    private bool gstd_ping(){

        bool ret = false;

        try{
            ret = factory.Ping();
        }catch(Error e){
            stderr.printf("Failed to reach gstd!\n");
            return ret;
        }

        stdout.printf ("pong\n");
        return ret;
    }


    private bool pipeline_get_property(dynamic DBus.Object pipeline, string[] args){

        bool ret = true;

        if(args[1]==null || args[2]==null || args[3]==null){
            stdout.printf("Missing argument.Execute:'help get'\n");
            return false;
        }

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

        if(args[1]==null || args[2]==null || args[3]==null || args[4]==null){
            stdout.printf("Missing argument.Execute:'help set'\n");
            return false;
        }

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

    private bool pipeline_get_state(dynamic DBus.Object pipeline){

        string state = pipeline.PipelineGetState();
        if (state==null){
            stderr.printf("Failed to get the pipeline state\n");
            return false;
        }

        stdout.printf(">>The pipeline state is: %s\n",state);
        return true;
    }

    private bool pipeline_seek(dynamic DBus.Object pipeline,string[] args){

        if(args[1]==null){
            stdout.printf("Missing argument.Execute:'help seek'\n");
            return false;
        }

        int pos_ms = args[1].to_int();
        bool ret = pipeline.PipelineSeek(pos_ms);
        if (!ret){
            stderr.printf("Seek fail: Media type not seekable\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_skip(dynamic DBus.Object pipeline,string[] args){

        if(args[1]==null){
            stdout.printf("Missing argument.Execute:'help skip'\n");
            return false;
        }

        int period_ms = args[1].to_int();
        bool ret = pipeline.PipelineSkip(period_ms);
        if (!ret){
            stderr.printf("Skip fail: Media type not seekable\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_speed(dynamic DBus.Object pipeline,string[] args){

        if(args[1]==null){
            stdout.printf("Missing argument.Execute:'help speed'\n");
            return false;
        }

        double rate = args[1].to_double();
        bool ret = pipeline.PipelineSpeed(rate);
        if (!ret){
            stderr.printf("Speed could not be set\n");
            return false;
        }
        return ret;
    }

    private bool pipeline_list(){

        string[] list = new string[20];
        string paths = "";
        int index = 0;

        for(index=0; index<list.length; index++){
            list[index] = null;
        }

        paths = factory.List();

        if (list==null){
            stderr.printf("There is no pipelines on factory!\n");
            return false;
        }

        list = paths.split(",",-1);
        stdout.printf("The actual pipelines are:\n");
        for(index=0; index<list.length; index++){
            stdout.printf("  %i. %s\n",index+1,list[index]);
        }
        return true;
    }

    /*
    *Create a proxy-object of the pipeline
    */
    public bool create_proxypipe(string? object_path){

        if(object_path == null || object_path[0] != '/')
            return false;

        /*Create a proxy-object of the pipeline*/
        pipeline = conn.get_object ("com.ridgerun.gstreamer.gstd",
                                     object_path,
                                    "com.ridgerun.gstreamer.gstd.PipelineInterface");
        try{
            bool ret=pipeline.PipelineIsInitialized();
            if(!ret) return false;
        }catch (Error e){
            return false;
        }

        return true;
    }

    /*
    *Parse entry-options or flags:
    *_signals:  flag to enable signals reception,
    *           useful when executing interactive console.
    *_debug:    flag to enable debug information
    *           when creating a pipeline.
    *obj_path:  option to specified the pipeline
    *           when executing a single command.
    *_remaining_args: command to be executed remains here,
    *                 if there is no remaining args interactive
    *                 console is enable.
    */
    public void parse_options(string[] args){

        /*Clean up global reference variables*/
        _signals = false;
        _debug = false;
        _remaining_args = null;
        obj_path = null;

        /*Parsing options*/
        var opt = new OptionContext("(For Commands HELP: 'gst-client help')");
        opt.set_help_enabled(true);
        opt.add_main_entries(options, null);

        try{
            opt.parse(ref args);
        } catch (GLib.OptionError e) {
            stderr.printf ("OptionError failure: %s\n",e.message);
        }
        if(cli_enable && obj_path!=null) active_pipe = obj_path;
    }

    /*
    * Parse single command
    */
    public bool parse_cmd(string[] args) throws DBus.Error, GLib.Error {

        if(!create_proxypipe(obj_path)){
            if (args[0].down() != "create" && args[0].down() != "help"
                && args[0].down() != "set-active" && args[0].down() != "quit"
                && args[0].down() != "list-pipes" && args[0].down() != "ping"
                && args[0].down() != "exit" && active_pipe == null){
                if(cli_enable)
                    stderr.printf("There is no active pipeline. See \"set-active\" or \"create\" command\n");
                else
                    stderr.printf("Pipeline path was not specified\n");
                return false;
            }

        }else if(_signals){

            /*Enable the reception of signals, if _signals flag was activated*/
            stdout.printf("Signals need to be fixed! \n");
            if(args[0].down() != "create" && args[0].down() != "help"){
                stdout.printf("Signals, activated\n");
                pipeline.Error += this.Error_cb;
                pipeline.Eos += this.Eos_cb;
                pipeline.StateChanged += this.StateChanged_cb;
            }
        }

        switch (args[0].down()){

        case "create":
            if(cli_enable){
                string[] description;
                /*Join command and split it using '\"'
                  character as reference*/
                description = string.joinv(" ",args).split("\"",-1);
                return pipeline_create(description[1]);
            }
            return pipeline_create(args[1]);

        case "destroy":
            return pipeline_destroy(pipeline);

        case "play":
            return pipeline_play(pipeline,true);

        case "pause":
            return pipeline_pause(pipeline,true);

        case "null":
            return pipeline_null(pipeline,true);

        case "play-async":
            return pipeline_play(pipeline,false);

        case "pause-async":
            return pipeline_pause(pipeline,false);

        case "null-async":
            return pipeline_null(pipeline,false);

        case "set":
            return pipeline_set_property(pipeline,args);

        case "get":
            return pipeline_get_property(pipeline,args);

        case "get-duration":
            return pipeline_get_duration(pipeline);

        case "get-position":
            return pipeline_get_position(pipeline);

        case "get-state":
            return pipeline_get_state(pipeline);

        case "seek":
            return pipeline_seek(pipeline,args);

        case "skip":
            return pipeline_skip(pipeline,args);

        case "speed":
            return pipeline_speed(pipeline,args);

        case "list-pipes":
            return pipeline_list();

        case "ping":
            return gstd_ping();

        case "set-active":
            if(cli_enable){
                active_pipe = args[1];
                if(! create_proxypipe(active_pipe))
                    stderr.printf ("Error: Invalid path\n");
                return true;
            }else{
                stderr.printf("This command is exclusive for interactive console mode\n");
                return false;
            }

        case "get-active":
            if(cli_enable){
                stdout.printf("The active pipeline path is:%s\n",active_pipe);
                return true;
            }else{
                stderr.printf("Command used only on the interactive console mode\n");
                return false;
            }

        case "quit":
            cli_enable = false;
            return true;

        case "exit":
            cli_enable = false;
            return true;

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
            stderr.printf("Unkown command:%s\n",args[0]);
            return false;
        }

        return true;
    }

    /*
    *Interactive Console management
    */
    public bool cli() throws DBus.Error, GLib.Error {

        string[] args;

        while (!stdin.eof()) {

            /*Get the command from the stdin*/
            var cmd_line = Readline.readline ("gst-client$ ");

            if (cmd_line != null) {
                /*Saving command on history*/
                Readline.History.add (cmd_line);

                /*Removes leading and trailing whitespace*/
                cmd_line.strip();

                /*Splits string into an array*/
                args = cmd_line.split(" ",-1);

                /*Execute the command*/
                if(args[0]!=null && cmd_line[0]!='#')
                    parse_cmd(args);

                /*Exit from cli*/
                if (!cli_enable) break;
            }
        }
        return true;
    }

    /*
    * Parse entry arguments
    * If there are no arguments,enable interactive console.
    */
    public bool parse(string[] args) throws DBus.Error, GLib.Error {
            if (args.length > 0) {
                /*Parse single command*/
                return parse_cmd(args);
            } else {
                /*Execute interactive console*/
                cli_enable = true;
                return cli();
            }
    }

    static int main (string[] args) {
        GstdCli cli;

        try {
            obj_path = null;
            cli = new GstdCli();

            /*Parse entry options or flags and
              fill the reference variables*/
            cli.parse_options(args);

            /*Parse commands*/
            if (!cli.parse(_remaining_args))
                return -1;

        } catch (DBus.Error e) {
            stderr.printf ("gst-client> DBus failure: %s\n",e.message);
            return 1;
        } catch (GLib.Error e) {
            stderr.printf ("gst-client> Dynamic method failure\n");
            return 1;
        }

        return 0;
    }
}