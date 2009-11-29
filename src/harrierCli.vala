using GLib;

public class HarrierCli : GLib.Object {
    private DBus.Connection conn;
    private dynamic DBus.Object harrier;

    public void run () throws DBus.Error, GLib.Error {
        conn = DBus.Bus.get (DBus.BusType.SESSION);
        harrier = conn.get_object ("com.ti.sdo.HarrierService",
                                   "/com/ti/sdo/HarrierObject",
                                   "com.ti.sdo.HarrierInterface");
	int id = harrier.CreatePipeline("videotestsrc ! ximagesink");
	if (id < 0) {
	    stdout.printf("Failed to create pipeline");
	} else {
	    stdout.printf("Pipe id is %d\n",id);
        bool r = harrier.PipelinePlay(id);
        if (!r){
            stdout.printf("Failed to put the pipe to play");
        }
        Posix.sleep(5);
//        r = harrier.PipelineNull(id);
        r = harrier.DestroyPipeline(id);
	}
    }

    static int main (string[] args) {
        var test = new HarrierCli ();
        try {
            test.run ();
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