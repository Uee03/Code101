import io
import json
import logging

from opentelemetry.sdk.metrics.export import InMemoryMetricReader
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter

from logging_json import JsonFormatter
from service import complete_task
from telemetry import build_telemetry, counter_total


def main() -> None:
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    logging.getLogger("taskservice").addHandler(handler)
    logging.getLogger("taskservice").setLevel(logging.INFO)

    exporter = InMemorySpanExporter()
    reader = InMemoryMetricReader()
    telemetry = build_telemetry("taskservice", SimpleSpanProcessor(exporter), reader)

    complete_task(telemetry, 1)

    spans = exporter.get_finished_spans()
    line = json.loads(stream.getvalue())
    print("span names:", [span.name for span in spans])
    print("span attributes:", dict(spans[0].attributes))
    print("log carries the span's trace id:", line["trace_id"] == format(spans[0].context.trace_id, "032x"))
    print("log message and field:", line["message"], line["task_id"])
    print("counter app.tasks.completed:", counter_total(reader, "app.tasks.completed"))


if __name__ == "__main__":
    main()
