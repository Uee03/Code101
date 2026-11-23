var counter = new Counter();
var history = new History();
history.Run(new Add(counter, 5));
Console.WriteLine($"value: {counter.Value}");
// TODO 2: run new Multiply(counter, 3) and print the value, then call history.Undo() twice, printing the value after each undo

// TODO 1: write Multiply : ICommand. The constructor receives the counter and a factor.
//         Execute() remembers the old value in _before and multiplies; Undo() puts _before back.

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
