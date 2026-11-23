RunTest("test one");
RunTest("test two");

static void Hit(Counter counter)
{
    counter.Value++;
}

static void RunTest(string name)
{
    var counter = new Counter();
    Hit(counter);
    Console.WriteLine($"{name}: counter is {counter.Value}");
}

class Counter
{
    public int Value { get; set; }
}
