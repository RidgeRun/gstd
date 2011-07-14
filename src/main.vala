/*
 * gstd/src/main.vala
 *
 * Main function for GStreamer daemon - framework for controlling audio and video streaming using D-Bus messages
 *
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
 *
 * GPL2 license - See http://www.opensource.org/licenses/gpl-2.0.php for complete text.
 */
using Gst;

/*Global Variable*/
public MainLoop loop = null;
public DBus.Connection conn = null;

private bool useSystemBus = false;
private bool useSessionBus = false;
private int debugLevel = 0; // 0 - error, 1 - warning, 2 - info, 3 - debug
private int signalPollRate = 0;
private bool enableWatchdog = false;
private const GLib.OptionEntry[] options = {
	{"system", '\0', 0, OptionArg.NONE, ref useSystemBus, "Use system bus", null},
	{"session", '\0', 0, OptionArg.NONE, ref useSessionBus, "Use session bus", null},
	{"debug", 'd', 0, OptionArg.INT, ref debugLevel, "Set debug level (0..3: error, warning, info, debug)", null},
#if GSTD_SUPPORT_SIGNALS
	{"signals", 's', 0, OptionArg.INT, ref signalPollRate, "Enable running thread to catch Posix signals and set poll rate in milliseconds (--signals=1000)", null},
#endif
#if GSTD_SUPPORT_WATCHDOG
	{"watchdog", 'w', 0, OptionArg.NONE, ref enableWatchdog, "Enable watchdog", null},
#endif
	{null}
};

public errordomain ErrorGstd
{
	OPTION,
	BUS,
	SERVICE_OWNERSHIP,
}

public int main (string[] args)
{
	GstdSignals signal_processor = null;
	Watchdog wd = null;

	try {
		Posix.openlog("gstd", Posix.LOG_PID, Posix.LOG_USER /*Posix.LOG_DAEMON*/);
		Posix.syslog(Posix.LOG_ERR, "Started");

		var opt = new GLib.OptionContext ("");
		opt.add_main_entries (options, null);

		try {
			opt.parse (ref args);
		}
		catch (GLib.OptionError e)
		{
			throw new ErrorGstd.OPTION("OptionError failure: %s", e.message);
		}

		switch (debugLevel) {
			case 0 :
				Posix.setlogmask(Posix.LOG_UPTO(Posix.LOG_ERR));
				break;
			case 1:
				Posix.setlogmask(Posix.LOG_UPTO(Posix.LOG_WARNING));
				break;
			case 2:
				Posix.setlogmask(Posix.LOG_UPTO(Posix.LOG_INFO));
				break;
			default:
				Posix.setlogmask(Posix.LOG_UPTO(Posix.LOG_DEBUG));
				break;
		}

		Posix.syslog(Posix.LOG_DEBUG, "Debug logging enabled");

		if (useSystemBus && useSessionBus)
		{
			throw new ErrorGstd.BUS("you have to choose: system or session bus");
		}

		/* Initializing GStreamer */
		Gst.init (ref args);

		/* Creating a GLib main loop with a default context */
		loop = new MainLoop (null, false);

		conn = DBus.Bus.get ((useSystemBus) ?
		                     DBus.BusType.SYSTEM :
		                     (useSessionBus) ?
		                     DBus.BusType.SESSION :
		                     DBus.BusType.STARTER);

		dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
		                                           "/org/freedesktop/DBus",
		                                           "org.freedesktop.DBus");

		/* Try to register service in session bus */
		uint request_name_result =
		    bus.request_name ("com.ridgerun.gstreamer.gstd", (uint)0);

		if (request_name_result != DBus.RequestNameReply.PRIMARY_OWNER)
		{
			throw new ErrorGstd.SERVICE_OWNERSHIP("Failed to obtain primary ownership of " +
			              "the service. This usually means there is another instance of " +
			              "gstd already running");
		}

		/* Create our factory */
		var factory = new Factory ();

		conn.register_object ("/com/ridgerun/gstreamer/gstd/factory", factory);

		if (signalPollRate > 0) 
			signal_processor = new GstdSignals (loop, factory, signalPollRate);

		if (enableWatchdog)
			wd = new Watchdog (1000);

		loop.run ();
	}
	catch (Error e)
	{
		Posix.syslog (Posix.LOG_ERR, "Error: %s", e.message);
	}

	Posix.syslog(Posix.LOG_ERR, "Ended");
	return 0;
}
