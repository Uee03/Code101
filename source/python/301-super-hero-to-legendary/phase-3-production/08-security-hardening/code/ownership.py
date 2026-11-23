from dataclasses import dataclass


class NotFound(Exception):
    pass


@dataclass(frozen=True)
class OwnedTask:
    id: int
    owner: str
    title: str


def get_task_for(tasks: dict[int, OwnedTask], task_id: int, caller: str) -> OwnedTask:
    task = tasks.get(task_id)
    if task is None or task.owner != caller:
        raise NotFound("task not found")
    return task


def public_view(task: OwnedTask) -> dict[str, object]:
    return {"id": task.id, "title": task.title}
