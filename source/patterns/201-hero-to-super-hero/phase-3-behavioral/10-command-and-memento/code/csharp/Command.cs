namespace CommandDemo;

public class Editor
{
    public string Text { get; set; } = "";
}

public interface ICommand
{
    void Execute();

    void Undo();
}

public class Append : ICommand
{
    private readonly Editor _editor;
    private readonly string _text;

    public Append(Editor editor, string text)
    {
        _editor = editor;
        _text = text;
    }

    public void Execute()
    {
        _editor.Text += _text;
    }

    public void Undo()
    {
        int keep = _editor.Text.Length - _text.Length;
        _editor.Text = _editor.Text.Substring(0, keep);
    }
}

public class Uppercase : ICommand
{
    private readonly Editor _editor;
    private string _before = "";

    public Uppercase(Editor editor)
    {
        _editor = editor;
    }

    public void Execute()
    {
        _before = _editor.Text;
        _editor.Text = _editor.Text.ToUpperInvariant();
    }

    public void Undo()
    {
        _editor.Text = _before;
    }
}

public class History
{
    private readonly Stack<ICommand> _done = new();

    public void Run(ICommand command)
    {
        command.Execute();
        _done.Push(command);
    }

    public bool Undo()
    {
        if (_done.Count == 0)
        {
            return false;
        }
        _done.Pop().Undo();
        return true;
    }
}

public static class Demo
{
    public static void Run()
    {
        var editor = new Editor();
        var history = new History();
        history.Run(new Append(editor, "Hello"));
        history.Run(new Append(editor, ", world"));
        Console.WriteLine($"text: [{editor.Text}]");
        history.Run(new Uppercase(editor));
        Console.WriteLine($"text: [{editor.Text}]");
        history.Undo();
        Console.WriteLine($"text: [{editor.Text}]");
        history.Undo();
        Console.WriteLine($"text: [{editor.Text}]");
        history.Undo();
        Console.WriteLine($"text: [{editor.Text}]");
        Console.WriteLine($"undo possible: {history.Undo()}");
    }
}
