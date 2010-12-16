/*using GLib;

public class Watchdog :
    Object
{
  private unowned Thread _thread;
  private int _counterMax;
  private int _counterMin;
  private int _counter;
  private MainContext _ctx;
  private MainLoop _loop;
  private TimeoutSource _timer;

  public Watchdog (uint timeoutInSec) throws ThreadError {
    _counter = _counterMin = _counterMax = (int) (timeoutInSec);

    //create a new event loop for the thread
    _ctx = new MainContext();
    _loop = new MainLoop (_ctx, false);

    //create a timer, which is used to check, if gstd is alive
    _timer = new TimeoutSource (1000);
    _timer.set_callback (() => {
      Check();
      return true;
    });
    _timer.attach (_loop.get_context());

    //create a new thread for the watchdog's mainloop
    assert(Thread.supported());
    _thread = Thread.create (() => {
      Posix.syslog (Posix.LOG_NOTICE, "watchdog thread!");
      _loop.run();
      Posix.syslog (Posix.LOG_NOTICE, "watchdog terminated!");
      return null;
    }, true);
    _thread.set_priority (ThreadPriority.URGENT);
  }

  ~Watchdog() {
    _loop.quit(); //TODO thread-safe?
    _thread.join();
  }

  public void Ping() {
    //Posix.syslog(Posix.LOG_DEBUG, "Ping");
    AtomicInt.set (ref _counter, _counterMax + 1);
  }

  private void Check() {
    AtomicInt.dec_and_test (ref _counter);
    int c = AtomicInt.get (ref _counter);
    if (c < _counterMin) {
      _counterMin = c;
      Posix.syslog (Posix.LOG_DEBUG, "watchdog counter reached new critical value: %d", _counterMin);
    }

    if (c <= 0) {
      Suicide();
    }
  }

  private void Suicide() {
    Posix.syslog (Posix.LOG_ERR, "Suicide");
    Posix.kill (Posix.getpid(), Posix.SIGINT); //TODO abort(); ?
    Posix.sleep(1);
    Posix.kill (Posix.getpid(), Posix.SIGKILL); //TODO abort(); ?
  }
}*/

