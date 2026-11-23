from fastapi import FastAPI, HTTPException
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from service import UnknownTask, complete_task
from telemetry import Telemetry


def create_app(telemetry: Telemetry) -> FastAPI:
    app = FastAPI(title="taskservice", docs_url=None, redoc_url=None)
    FastAPIInstrumentor.instrument_app(
        app, tracer_provider=telemetry.tracer_provider, meter_provider=telemetry.meter_provider
    )

    @app.post("/tasks/{task_id}/complete")
    async def complete(task_id: int) -> dict[str, object]:
        try:
            return complete_task(telemetry, task_id)
        except UnknownTask:
            raise HTTPException(status_code=404, detail="Task not found") from None

    return app
