import os

import uvicorn

from app import create_app
from logging_json import configure_logging
from telemetry import otlp_telemetry


def main() -> None:
    configure_logging()
    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4318")
    telemetry = otlp_telemetry("taskservice", endpoint)
    uvicorn.run(create_app(telemetry), host="127.0.0.1", port=8000, log_config=None)


if __name__ == "__main__":
    main()
