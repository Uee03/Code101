import io
import json
import logging
import unittest

from fastapi.testclient import TestClient
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.metrics.export import InMemoryMetricReader
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter
from opentelemetry.trace import StatusCode

from app import create_app
from logging_json import JsonFormatter
from service import UnknownTask, complete_task
from telemetry import build_telemetry, counter_total


class ObservabilityTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.stream = io.StringIO()
        self.handler = logging.StreamHandler(self.stream)
        self.handler.setFormatter(JsonFormatter())
        logger = logging.getLogger("taskservice")
        logger.addHandler(self.handler)
        logger.setLevel(logging.INFO)
        self.exporter = InMemorySpanExporter()
        self.reader = InMemoryMetricReader()
        self.telemetry = build_telemetry("taskservice", SimpleSpanProcessor(self.exporter), self.reader)

    def tearDown(self) -> None:
        logging.getLogger("taskservice").removeHandler(self.handler)

    def log_lines(self) -> list[dict]:
        return [json.loads(line) for line in self.stream.getvalue().splitlines()]


class ServiceTests(ObservabilityTestCase):
    def test_a_completed_task_makes_a_span_a_correlated_log_and_a_count(self) -> None:
        complete_task(self.telemetry, 1)
        (span,) = self.exporter.get_finished_spans()
        (line,) = self.log_lines()
        self.assertEqual(span.name, "complete_task")
        self.assertEqual(dict(span.attributes), {"task.id": 1})
        self.assertEqual(line["trace_id"], format(span.context.trace_id, "032x"))
        self.assertEqual(line["span_id"], format(span.context.span_id, "016x"))
        self.assertEqual(counter_total(self.reader, "app.tasks.completed"), 1)

    def test_an_unknown_task_marks_the_span_as_an_error_and_is_not_counted(self) -> None:
        with self.assertRaises(UnknownTask):
            complete_task(self.telemetry, 99)
        (span,) = self.exporter.get_finished_spans()
        self.assertEqual(span.status.status_code, StatusCode.ERROR)
        self.assertEqual(self.log_lines()[0]["level"], "WARNING")
        self.assertEqual(counter_total(self.reader, "app.tasks.completed"), 0)


class LoggingTests(ObservabilityTestCase):
    def test_sensitive_fields_are_redacted(self) -> None:
        logging.getLogger("taskservice").info(
            "login", extra={"fields": {"task_id": 1, "Password": "hunter2"}}
        )
        self.assertNotIn("hunter2", self.stream.getvalue())
        self.assertEqual(self.log_lines()[0]["Password"], "[redacted]")

    def test_a_line_outside_any_span_has_no_trace_id(self) -> None:
        logging.getLogger("taskservice").info("startup")
        self.assertNotIn("trace_id", self.log_lines()[0])


class HttpTests(ObservabilityTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.app = create_app(self.telemetry)
        self.client = TestClient(self.app)

    def tearDown(self) -> None:
        FastAPIInstrumentor.uninstrument_app(self.app)
        super().tearDown()

    def test_the_business_span_is_a_child_of_the_request_span(self) -> None:
        response = self.client.post("/tasks/1/complete")
        self.assertEqual(response.status_code, 200)
        business = [s for s in self.exporter.get_finished_spans() if s.name == "complete_task"]
        self.assertEqual(len(business), 1)
        self.assertIsNotNone(business[0].parent)

    def test_an_unknown_task_is_a_404(self) -> None:
        self.assertEqual(self.client.post("/tasks/99/complete").status_code, 404)


if __name__ == "__main__":
    unittest.main()
