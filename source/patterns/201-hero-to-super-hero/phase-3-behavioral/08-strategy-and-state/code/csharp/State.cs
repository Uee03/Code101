namespace StateDemo;

public abstract class State
{
    public abstract string Name { get; }

    public virtual void Submit(Document doc) =>
        throw new InvalidOperationException($"Cannot submit a {Name} document");

    public virtual void Approve(Document doc) =>
        throw new InvalidOperationException($"Cannot approve a {Name} document");

    public virtual void Reject(Document doc) =>
        throw new InvalidOperationException($"Cannot reject a {Name} document");
}

public class Draft : State
{
    public override string Name => "draft";

    public override void Submit(Document doc) => doc.SetState(new InReview());
}

public class InReview : State
{
    public override string Name => "review";

    public override void Approve(Document doc) => doc.SetState(new Published());

    public override void Reject(Document doc) => doc.SetState(new Draft());
}

public class Published : State
{
    public override string Name => "published";
}

public class Document
{
    private State _state = new Draft();

    public void SetState(State state)
    {
        _state = state;
    }

    public string Status() => _state.Name;

    public void Submit() => _state.Submit(this);

    public void Approve() => _state.Approve(this);

    public void Reject() => _state.Reject(this);
}

public static class Demo
{
    public static void Run()
    {
        var doc = new Document();
        Console.WriteLine($"status: {doc.Status()}");
        doc.Submit();
        Console.WriteLine($"status: {doc.Status()}");
        doc.Reject();
        Console.WriteLine($"status: {doc.Status()}");
        doc.Submit();
        doc.Approve();
        Console.WriteLine($"status: {doc.Status()}");
        try
        {
            doc.Submit();
        }
        catch (InvalidOperationException error)
        {
            Console.WriteLine($"Error: {error.Message}");
        }
    }
}
