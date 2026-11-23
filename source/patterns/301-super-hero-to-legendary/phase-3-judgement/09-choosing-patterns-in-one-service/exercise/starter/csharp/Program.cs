var task = new WorkItem(1, "alice");
foreach (var (actor, newAssignee) in new[] { ("carol", "bob"), ("alice", "dave"), ("carol", "bob") })
{
    try
    {
        task.Reassign(newAssignee, actor);
        Console.WriteLine($"task {task.Id} now belongs to {task.Assignee}");
    }
    catch (DomainException error)
    {
        Console.WriteLine($"rejected: {error.Message}");
    }
}

class DomainException(string message) : Exception(message);

class WorkItem(int id, string assignee)
{
    private const string Lead = "carol";

    public int Id { get; } = id;
    public string Assignee { get; private set; } = assignee;

    public void Reassign(string newAssignee, string actor)
    {
        // TODO 1: throw new DomainException($"{actor} is not the lead") unless actor equals the constant Lead.
        // TODO 2: throw new DomainException($"task {Id} already belongs to {newAssignee}") when nothing would change.
        // TODO 3: otherwise set the new assignee.
        throw new NotImplementedException();
    }
}
