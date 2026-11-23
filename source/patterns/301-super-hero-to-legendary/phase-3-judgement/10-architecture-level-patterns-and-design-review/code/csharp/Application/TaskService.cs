using TasksApp.Domain;

namespace TasksApp.Application;

public class TaskService(ITaskStore store)
{
    public TaskItem Complete(int id)
    {
        var task = store.Get(id);
        task.Complete();
        store.Save(task);
        return task;
    }
}
