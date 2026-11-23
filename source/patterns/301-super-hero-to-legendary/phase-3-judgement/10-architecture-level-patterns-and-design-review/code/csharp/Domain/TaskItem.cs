namespace TasksApp.Domain;

public class TaskItem(int id, string title)
{
    public int Id { get; } = id;
    public string Title { get; } = title;
    public bool Done { get; private set; }

    public void Complete()
    {
        if (Done)
        {
            throw new InvalidOperationException($"task {Id} is already done");
        }
        Done = true;
    }
}
