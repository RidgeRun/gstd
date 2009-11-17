using Gst;

[DBus (name = "com.ti.sdo.HarrierInterface")]
public class Harrier : GLib.Object {

    public void hello(){
	stdout.printf("Hello World\n");
    }
}