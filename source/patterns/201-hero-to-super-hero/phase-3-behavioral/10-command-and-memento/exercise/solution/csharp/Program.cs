var counter = new Counter();
var history = new History();
history.Run(new Add(counter, 5));
Console.WriteLine($"value: {counter.Value}");
history.Run(new Multiply(counter, 3));
Console.WriteLine($"value: {counter.Value}");
history.Undo();
Console.WriteLine($"value: {counter.Value}");
history.Undo();
Console.WriteLine($"value: {counter.Value}");

class Counter
{
    public int Value { get; set; }
}

interface ICommand
{
    void Execute();

    void Undo();
}

class Add : ICommand
{
    private readonly Counter _counter;
    private readonly int _amount;

    public Add(Counter counter, int amount)
    {
        _counter = counter;
        _amount = amount;
    }

    public void Execute()
    {
        _counter.Value += _amount;
    }

    public void Undo()
    {
        _counter.Value -= _amount;
    }
}

class Multiply : ICommand
{
    private readonly Counter _counter;
    private readonly int _factor;
    private int _before;

    public Multiply(Counter counter, int factor)
    {
        _counter = counter;
        _factor = factor;
    }

    public void Execute()
    {
        _before = _counter.Value;
        _counter.Value *= _factor;
    }

    public void Undo()
    {
        _counter.Value = _before;
    }
}

class History
{
    private readonly Stack<ICommand> _done = new();

    public void Run(ICommand command)
    {
        command.Execute();
        _done.Push(command);
    }

    public void Undo()
    {
        _done.Pop().Undo();
    }
}
