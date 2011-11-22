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

/*Global Variable*/
private bool useSystemBus = false;
private bool useSessionBus = false;
private int debugLevel = 0; // 0 - error, 1 - warning, 2 - info, 3 - debug
private int signalPollRate = 0;
private const GLib.OptionEntry[] options = {
	{"system", '\0', 0, OptionArg.NONE, ref useSystemBus, "Use system bus", null},
	{"session", '\0', 0, OptionArg.NONE, ref useSessionBus, "Use session bus", null},
	{"debug", 'd', 0, OptionArg.INT, ref debugLevel, "Set debug level (0..3: error, warning, info, debug)", null},
#if GSTD_SUPPORT_SIGNALS
	{"signals", 's', 0, OptionArg.INT, ref signalPollRate, "Enable running thread to catch Posix signals and set poll rate in milliseconds (--signals=1000)", null},
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

		if (signalPollRate > 0) 
			signal_processor = new GstdSignals ();

		if (useSystemBus && useSessionBus)
		{
			throw new ErrorGstd.BUS("you have to choose: system or session bus");
		}

		/* Initializing GStreamer */
		Gst.init (ref args);

		/* Creating a GLib main loop with a default context */
		MainLoop loop = new MainLoop (null, false);

		/* Connect to DBus */
		GLib.DBusConnection connection = GLib.Bus.get_sync((useSystemBus) ?
		                                               GLib.BusType.SYSTEM :
		                                               (useSessionBus) ?
		                                                 GLib.BusType.SESSION :
		                                                 GLib.BusType.STARTER);

		/* Create the factory */
		Factory factory = new Factory (connection);

		/* Register factory to DBus */
		GLib.Bus.own_name_on_connection (
			connection,
			"com.ridgerun.gstreamer.gstd",
			GLib.BusNameOwnerFlags.NONE,
			(connection, name) =>
			{
				try
				{
					connection.register_object ("/com/ridgerun/gstreamer/gstd/factory", factory);
				}
				catch (IOError e)
				{
					Posix.syslog(Posix.LOG_ERR, "Could not register service");
					loop.quit();
				}
			},
			(connection, name) => 
			{
				Posix.syslog(Posix.LOG_ERR, "Lost bus name");
				loop.quit();
			}
		);

		/* Start signal processor */
		if (signal_processor != null) 
			signal_processor.monitor (loop, factory, signalPollRate);

		/* Run main loop */
		loop.run ();
	}
	catch (Error e)
	{
		Posix.syslog (Posix.LOG_ERR, "Error: %s", e.message);
	}

	Posix.syslog(Posix.LOG_ERR, "Ended");
	return 0;
}
