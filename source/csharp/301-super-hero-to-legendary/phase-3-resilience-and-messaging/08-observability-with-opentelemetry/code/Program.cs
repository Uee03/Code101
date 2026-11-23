using ObservedApi;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

const string serviceName = "orders-api";
const string serviceVersion = "1.0.0";

var builder = WebApplication.CreateBuilder(args);

// Logs: every log line also goes to the collector, carrying the trace id of the request that wrote it.
builder.Logging.AddOpenTelemetry(logging =>
{
    logging.IncludeFormattedMessage = true;
    logging.IncludeScopes = true;
    logging.SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName, serviceVersion: serviceVersion));
    logging.AddOtlpExporter();
});

// Traces and metrics. The endpoint comes from OTEL_EXPORTER_OTLP_ENDPOINT (default http://localhost:4317).
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource.AddService(serviceName, serviceVersion: serviceVersion))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSource(Telemetry.ActivitySourceName)
        .AddOtlpExporter())
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddMeter(Telemetry.MeterName)
        .AddOtlpExporter());

var app = builder.Build();

app.MapGet("/orders/{id:int}", (int id, ILogger<Program> logger) =>
{
    // A custom span inside the request span the framework already created.
    using var activity = Telemetry.Source.StartActivity("pricing.calculate");
    var totalCents = id * 1250;
    activity?.SetTag("order.id", id);
    activity?.SetTag("order.total_cents", totalCents);

    // A metric tag must have few distinct values. Never use an order id, user id or URL here.
    Telemetry.OrdersRead.Add(1, new KeyValuePair<string, object?>("order.kind", id % 2 == 0 ? "even" : "odd"));

    // Structured logging: the template stays constant, the values become searchable fields.
    logger.LogInformation("Priced order {OrderId} at {TotalCents} cents", id, totalCents);
    return Results.Ok(new { id, totalCents });
});

app.MapGet("/fail", (ILogger<Program> logger) =>
{
    logger.LogWarning("About to fail on purpose");
    throw new InvalidOperationException("demo failure");
});

app.Run();
