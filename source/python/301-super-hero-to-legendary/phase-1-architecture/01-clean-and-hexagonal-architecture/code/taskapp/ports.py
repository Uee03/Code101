from datetime import datetime
from typing import Protocol

from taskapp.domain import Task


class TaskRepository(Protocol):
    def get(self, task_id: int) -> Task | None: ...

    def save(self, task: Task) -> None: ...


class Clock(Protocol):
    def now(self) -> datetime: ...


class Notifier(Protocol):
    def task_completed(self, task: Task) -> None: ...
