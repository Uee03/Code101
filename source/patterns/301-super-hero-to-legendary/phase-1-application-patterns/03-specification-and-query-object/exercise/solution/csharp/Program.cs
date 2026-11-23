var tasks = new List<WorkItem>
{
    new(1, "alice", "todo"),
    new(2, "alice", "done"),
    new(3, "bob", "todo"),
    new(4, "alice", "in_progress"),
};

Console.WriteLine($"alice open: {Ids(new AssigneeSpec("alice").And(new StatusSpec("done").Not()))}");
Console.WriteLine($"not alice: {Ids(new AssigneeSpec("alice").Not())}");

string Ids(Spec spec) => "[" + string.Join(", ", tasks.Where(spec.Matches).Select(t => t.Id)) + "]";

record WorkItem(int Id, string Assignee, string Status);

abstract class Spec
{
    public abstract bool Matches(WorkItem task);

    public Spec And(Spec other) => new AndSpec(this, other);

    public Spec Not() => new NotSpec(this);
}

class AndSpec(Spec left, Spec right) : Spec
{
    public override bool Matches(WorkItem task) => left.Matches(task) && right.Matches(task);
}

class NotSpec(Spec inner) : Spec
{
    public override bool Matches(WorkItem task) => !inner.Matches(task);
}

class StatusSpec(string status) : Spec
{
    public override bool Matches(WorkItem task) => task.Status == status;
}

class AssigneeSpec(string assignee) : Spec
{
    public override bool Matches(WorkItem task) => task.Assignee == assignee;
}
