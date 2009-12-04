using Gst;

/*Global Variable*/
public MainLoop loop;

public void main (string[] args) {
    /* Initializing GStreamer */
    Gst.init (ref args);

    stdout.printf("Harrier Streaming Server Daemon\n");

    /* Creating a GLib main loop with a default context */
    loop = new MainLoop (null, false);

    try {
        var conn = DBus.Bus.get (DBus.BusType.SESSION);

        dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                                   "/org/freedesktop/DBus",
                                                   "org.freedesktop.DBus");

        /* Try to register service in session bus */
        uint request_name_result = bus.request_name (
            "com.ti.sdo.HarrierService", (uint) 0);

        if (request_name_result == DBus.RequestNameReply.PRIMARY_OWNER) {
            /* Create our bird*/
            var hawk = new Harrier();

            conn.register_object ("/com/ti/sdo/HarrierObject", hawk);

            stdout.printf("Listening for connections...\n");
            loop.run ();
        } else {
            stderr.printf("Failed to obtain primary ownership of the service\n");
            stderr.printf("This usually means there is another instance of " +
                "harrier already running\n");
        }
    } catch (Error e) {
        stderr.printf ("Oops: %s\n", e.message);
    }
}
