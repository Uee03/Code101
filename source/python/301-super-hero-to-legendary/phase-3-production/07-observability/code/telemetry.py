from dataclasses import dataclass

from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.metrics import Counter, Histogram
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import (
    InMemoryMetricReader,
    MetricReader,
    PeriodicExportingMetricReader,
)
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import SpanProcessor, TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace import Tracer


@dataclass
class Telemetry:
    tracer_provider: TracerProvider
    meter_provider: MeterProvider
    tracer: Tracer
    completed: Counter
    duration: Histogram


def build_telemetry(
    service_name: str, span_processor: SpanProcessor, metric_reader: MetricReader
) -> Telemetry:
    resource = Resource.create({"service.name": service_name})
    tracer_provider = TracerProvider(resource=resource)
    tracer_provider.add_span_processor(span_processor)
    meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
    meter = meter_provider.get_meter("taskservice")
    return Telemetry(
        tracer_provider=tracer_provider,
        meter_provider=meter_provider,
        tracer=tracer_provider.get_tracer("taskservice"),
        completed=meter.create_counter(
            "app.tasks.completed", unit="{task}", description="Tasks completed"
        ),
        duration=meter.create_histogram(
            "app.task.complete.duration", unit="s", description="Time to complete a task"
        ),
    )


def otlp_telemetry(service_name: str, endpoint: str) -> Telemetry:
    return build_telemetry(
        service_name,
        BatchSpanProcessor(OTLPSpanExporter(endpoint=f"{endpoint}/v1/traces")),
        PeriodicExportingMetricReader(
            OTLPMetricExporter(endpoint=f"{endpoint}/v1/metrics"), export_interval_millis=10_000
        ),
    )


def counter_total(reader: InMemoryMetricReader, name: str) -> float:
    data = reader.get_metrics_data()
    if data is None:
        return 0
    total = 0
    for resource_metrics in data.resource_metrics:
        for scope_metrics in resource_metrics.scope_metrics:
            for metric in scope_metrics.metrics:
                if metric.name == name:
                    total += sum(point.value for point in metric.data.data_points)
    return total
