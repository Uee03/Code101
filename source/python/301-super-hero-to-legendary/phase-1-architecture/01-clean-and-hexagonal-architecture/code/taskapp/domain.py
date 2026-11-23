from dataclasses import dataclass, replace
from datetime import datetime
from enum import Enum


class TaskStatus(Enum):
    OPEN = "open"
    DONE = "done"


class DomainError(Exception):
    """A business rule was broken."""


@dataclass(frozen=True)
class Task:
    id: int
    title: str
    status: TaskStatus = TaskStatus.OPEN
    completed_at: datetime | None = None

    def complete(self, now: datetime) -> "Task":
        if self.status is TaskStatus.DONE:
            raise DomainError(f"task {self.id} is already done")
        return replace(self, status=TaskStatus.DONE, completed_at=now)
