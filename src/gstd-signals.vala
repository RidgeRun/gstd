/*
 * gstd/src/gstd-signals.vala
 *
 * Posix signal handling for GStreamer daemon
 *
 * Use a separate thread to catch signals to avoid deadlock issues
 * that occur when a random GStreamer thread is allowed to catch signals.
 * Using a separate thread ensures the thread processing the signal is
 * not holding a lock on critical resource.
 *
 * Copyright (c) 2011, RidgeRun
 * All rights reserved.
 *
 * GPL2 license - See http://www.opensource.org/licenses/gpl-2.0.php for complete text.
 */

namespace gstd
{

public class Signals : GLib.Object {
#if GSTD_SUPPORT_SIGNALS
	private FactoryInterface _factory = null;
	private MainLoop _loop = null;
	private int _caught_intr = -1;
	private unowned Thread<void*> _thread;
	private sigset_t _sigset;    // fixme: should be local to constructor - throws error: use of possibly unassigned local variable
	private sigset_t old_sigset; // fixme: should be local to constructor

	public Signals () throws ThreadError {
		int err;

		sigfillset (_sigset);
		err = sigprocmask (SIG_BLOCK, _sigset, old_sigset);
		if (err != 0) {
			Posix.syslog (Posix.LOG_ERR, "sigprocmask returned an error\n");
		}

		_thread = Thread.create<void*> (sig_thread, true);
		_thread.set_priority (ThreadPriority.URGENT);
		Posix.syslog (Posix.LOG_DEBUG, "Created signal monitor thread\n");
    	}

	~Signals () {
		Posix.syslog (Posix.LOG_DEBUG, "Destroying signal monitor thread\n");
		_thread = null;
	}

	public void monitor(MainLoop loop, FactoryInterface factory, uint pollrate_ms) {
		_loop = loop;
		_factory = factory;

		Posix.syslog (Posix.LOG_DEBUG, "Monitoring signals\n");
		Timeout.add (pollrate_ms, check_interrupt);
		GLib.assert (Thread.supported ());
}

	private bool check_interrupt () {
   		if (_caught_intr < 0)
      			return true;

		if ((_loop == null) || (_factory == null)) {
			Posix.syslog (Posix.LOG_DEBUG, "Delaying signal processing until gstd finishes initialization\n");
		}

		switch (_caught_intr) {
			case SIGTERM:
				Posix.syslog (Posix.LOG_DEBUG, "Handling SIGTERM signal\n");
				_factory.destroy_all ();
				_loop.quit ();
				break;
			default:
				Posix.syslog (Posix.LOG_DEBUG, "Unhandled signal %d\n", _caught_intr);
				break;
		}

		_caught_intr = -1;
	   	return true;
	}

	private void* sig_thread () {
		int sig;
		int err;

		sigfillset (_sigset);
		
		do {
			err = sigwait (_sigset, out sig);

			Posix.syslog (Posix.LOG_DEBUG, "Signal monitor thread returned from sigwait()\n");

			if (err != 0) {
				Posix.syslog (Posix.LOG_ERR, "sigwait returned an error\n");
				continue;
			}

			_caught_intr = sig;
		} while (true);
	}

#else
	public Signals () {
    	}

	public void monitor(MainLoop loop, FactoryInterface factory, uint pollrate_ms) {
	}

	~Signals () {
   	}
#endif
}

}

