namespace MediatorDemo;

public interface IMediator
{
    void Changed(Component sender);
}

public abstract class Component
{
    private readonly IMediator _mediator;

    protected Component(IMediator mediator, string label)
    {
        _mediator = mediator;
        Label = label;
    }

    public string Label { get; }

    protected void Notify() => _mediator.Changed(this);
}

public class TextBox : Component
{
    public TextBox(IMediator mediator, string label) : base(mediator, label)
    {
    }

    public string Text { get; private set; } = "";

    public void SetText(string text)
    {
        Text = text;
        Notify();
    }
}

public class Checkbox : Component
{
    public Checkbox(IMediator mediator, string label) : base(mediator, label)
    {
    }

    public bool Checked { get; private set; }

    public void SetChecked(bool value)
    {
        Checked = value;
        Notify();
    }
}

public class SignupForm : IMediator
{
    public SignupForm()
    {
        Name = new TextBox(this, "name");
        Terms = new Checkbox(this, "terms");
    }

    public TextBox Name { get; }

    public Checkbox Terms { get; }

    public bool RegisterEnabled { get; private set; }

    public void Changed(Component sender)
    {
        RegisterEnabled = Name.Text.Length > 0 && Terms.Checked;
        Console.WriteLine($"{sender.Label} changed -> register enabled: {RegisterEnabled}");
    }
}

public static class Demo
{
    public static void Run()
    {
        var form = new SignupForm();
        form.Name.SetText("ana");
        form.Terms.SetChecked(true);
        form.Name.SetText("");
    }
}
