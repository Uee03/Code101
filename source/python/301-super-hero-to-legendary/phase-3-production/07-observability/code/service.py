import logging
import time

from telemetry import Telemetry

logger = logging.getLogger("taskservice")
KNOWN_TASKS = {1, 2, 3}


class UnknownTask(Exception):
    pass


def complete_task(telemetry: Telemetry, task_id: int) -> dict[str, object]:
    start = time.perf_counter()
    outcome = "error"
    try:
        with telemetry.tracer.start_as_current_span("complete_task") as span:
            span.set_attribute("task.id", task_id)
            if task_id not in KNOWN_TASKS:
                outcome = "not_found"
                logger.warning("task not found", extra={"fields": {"task_id": task_id}})
                raise UnknownTask(task_id)
            logger.info("task completed", extra={"fields": {"task_id": task_id}})
            telemetry.completed.add(1)
            outcome = "completed"
            return {"task_id": task_id, "status": "done"}
    finally:
        telemetry.duration.record(time.perf_counter() - start, {"outcome": outcome})
