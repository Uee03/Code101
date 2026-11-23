using TasksApp.Domain;

namespace TasksApp.Application;

public interface ITaskStore
{
    TaskItem Get(int id);

    void Save(TaskItem task);
}
