RunTest("test one");
RunTest("test two");

static void Hit()
{
    // TODO 1: receive a Counter as a parameter, increment that counter and stop using Counter.Instance.
    Counter.Instance.Value++;
}

static void RunTest(string name)
{
    // TODO 2: create a new Counter here and pass it to Hit.
    Hit();
    // TODO 3: print the value of the counter you created instead of the shared one.
    Console.WriteLine($"{name}: counter is {Counter.Instance.Value}");
}

class Counter
{
    private static Counter? _instance;

    public static Counter Instance => _instance ??= new Counter();

    public int Value { get; set; }
}
