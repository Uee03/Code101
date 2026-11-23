using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace ObservedApi;

// Names are part of your contract with the dashboards: change them deliberately, never by accident.
public static class Telemetry
{
    public const string ActivitySourceName = "ObservedApi";
    public const string MeterName = "ObservedApi";

    public static readonly ActivitySource Source = new(ActivitySourceName);

    private static readonly Meter Meter = new(MeterName);

    public static readonly Counter<long> OrdersRead =
        Meter.CreateCounter<long>("orders.read", unit: "{order}", description: "Orders read through the API.");
}
