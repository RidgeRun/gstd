using GLib;

public class HarrierCli : GLib.Object {
    private DBus.Connection conn;
    private dynamic DBus.Object harrier;
    private int counter = 0;

    public void birdIsDead(dynamic DBus.Object harrier){
	stdout.printf("Our bird just died :'( \n");
	stdout.printf("\n\n");
	counter++;
    }

    public void run () throws DBus.Error, GLib.Error {
        conn = DBus.Bus.get (DBus.BusType.SESSION);
        harrier = conn.get_object ("com.ti.sdo.HarrierService",
                                   "/com/ti/sdo/HarrierObject",
                                   "com.ti.sdo.HarrierInterface");
	harrier.Dying += birdIsDead;
	harrier.hello(counter);
	stdout.printf("Counter is %d\n",counter);
	harrier.bye();
	stdout.printf("Counter is %d\n",counter);
    }

    static int main (string[] args) {
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

        return 0;
    }
}