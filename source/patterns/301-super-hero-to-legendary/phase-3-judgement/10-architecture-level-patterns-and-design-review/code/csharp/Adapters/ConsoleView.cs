using TasksApp.Domain;

namespace TasksApp.Adapters;

public static class ConsoleView
{
    public static string Render(TaskItem task) => $"completed: {task.Title} is done={task.Done}";
}
