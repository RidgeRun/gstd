using GLib;

public class HarrierCli : GLib.Object {
    private DBus.Connection conn;
    private dynamic DBus.Object harrier;

    public void run () throws DBus.Error, GLib.Error {
        conn = DBus.Bus.get (DBus.BusType.SESSION);
        harrier = conn.get_object ("com.ti.sdo.HarrierService",
                                   "/com/ti/sdo/HarrierObject",
                                   "com.ti.sdo.HarrierInterface");
	stdout.printf("Ready to call hello 2\n");
	harrier.hello();
	stdout.printf("Hello called\n");
    }

    static int main (string[] args) {
        var loop = new MainLoop (null, false);

        var test = new HarrierCli ();
        try {
            test.run ();
        } catch (DBus.Error e) {
            stderr.printf ("Failed to initialize");
            return 1;
        } catch (GLib.Error e) {
            stderr.printf ("Dynamic method failure");
            return 1;
        }

        loop.run ();

        return 0;
    }
}