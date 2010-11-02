using GLib;

public class Watchdog :
    Object
{
    private unowned Thread _thread;
    private int _counterMax;
    private int _counter;
    private MainLoop _loop;
    private TimeoutSource _timer;

    public Watchdog(uint timeoutInSec) throws ThreadError
    {
        _counterMax = (int)(timeoutInSec);
        _counter = _counterMax;

        //create a new event loop for the thread
        _loop = new MainLoop (null, false);

         //create a timer, which ise used to check, if gstd is alive
         _timer = new TimeoutSource(1000);
         _timer.set_callback(() => {
           Check();
           return true;
         });
         _timer.attach(loop.get_context());

        //create a new thread for teh watch dog itself
        _thread = Thread.create(() => {
            stdout.printf("watchdog thread!\n");
            _loop.run();
            stdout.printf("watchdog terminated!\n");
            return null;
         }, true);
    }

    ~Watchdog()
    {
        //stderr.printf("dtor\n");
        _loop.quit(); //TODO thread-safe?
        _thread.join();
    }

    public void Ping()
    {
        //stderr.printf("Ping\n");
        AtomicInt.set(ref _counter, _counterMax);
    }

    private void Check()
    {
        //stderr.printf("Check\n");
        if (AtomicInt.dec_and_test(ref _counter))
        {
            Suicide();
        }
    }

    private void Suicide()
    {
        stderr.printf("Suicide\n");
        Posix.kill(Posix.getpid(), Posix.SIGKILL); //TODO abort(); ?
    }
}
