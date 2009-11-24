using Gst;

[DBus (name = "com.ti.sdo.HarrierInterface", signals = "Dying")]
public class Harrier : GLib.Object {
    public signal void Dying();

    public void hello(int count){
	stdout.printf("Hello World, and counter is:%d\n",count);
    }
    
    public void bye(){
	stdout.printf("See you later world!\n");
	Dying();
    }
}