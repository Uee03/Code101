using TasksApp.Adapters;
using TasksApp.Application;
using TasksApp.Domain;

var store = new InMemoryTaskStore([new TaskItem(1, "Write ADR")]);
var service = new TaskService(store);
Console.WriteLine(ConsoleView.Render(service.Complete(1)));

var (files, problems) = ArchitectureCheck.CheckTree(Directory.GetCurrentDirectory());
Console.WriteLine($"architecture check: {files} files, {problems.Count} violations");
var bad = ArchitectureCheck.CheckSource("Domain", "using TasksApp.Adapters;");
Console.WriteLine($"bad snippet: {bad[0]}");
