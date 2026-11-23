from datetime import datetime

from taskapp.domain import Task


class InMemoryTaskRepository:
    def __init__(self, tasks: list[Task] | None = None) -> None:
        self._tasks = {task.id: task for task in tasks or []}

    def get(self, task_id: int) -> Task | None:
        return self._tasks.get(task_id)

    def save(self, task: Task) -> None:
        self._tasks[task.id] = task


class FixedClock:
    def __init__(self, moment: datetime) -> None:
        self._moment = moment

    def now(self) -> datetime:
        return self._moment


class RecordingNotifier:
    def __init__(self) -> None:
        self.completed: list[int] = []

    def task_completed(self, task: Task) -> None:
        self.completed.append(task.id)
