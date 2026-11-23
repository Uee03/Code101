using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddOptions<NotesOptions>()
    .BindConfiguration(NotesOptions.SectionName)
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddSingleton<InstanceCounter>();
builder.Services.AddSingleton<SingletonService>();
builder.Services.AddScoped<ScopedService>();
builder.Services.AddTransient<TransientService>();
builder.Services.AddScoped<LifetimeProbe>();
builder.Services.AddSingleton<ITitleFormatter, UpperTitleFormatter>();
builder.Services.AddScoped<TitleService>();

var app = builder.Build();

app.MapGet("/lifetimes", (
    ScopedService scoped,
    TransientService transient,
    LifetimeProbe probe,
    InstanceCounter counter) => new
{
    scopedShared = ReferenceEquals(scoped, probe.Scoped),
    transientShared = ReferenceEquals(transient, probe.Transient),
    singletonInstances = counter.Singleton,
    scopedInstances = counter.Scoped,
    transientInstances = counter.Transient,
});

app.MapGet("/heading", (TitleService titles) => titles.Heading());
app.MapGet("/settings/static", (IOptions<NotesOptions> options) => options.Value);
app.MapGet("/settings/live", (IOptionsMonitor<NotesOptions> options) => options.CurrentValue);

app.Run();
