using TasksApp.Application;
using TasksApp.Domain;

namespace TasksApp.Adapters;

public class InMemoryTaskStore(IEnumerable<TaskItem> tasks) : ITaskStore
{
    private readonly Dictionary<int, TaskItem> _tasks = tasks.ToDictionary(t => t.Id);

    public TaskItem Get(int id) => _tasks[id];

    public void Save(TaskItem task) => _tasks[task.Id] = task;
}
