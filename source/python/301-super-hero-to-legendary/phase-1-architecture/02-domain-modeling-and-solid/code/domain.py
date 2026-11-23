from dataclasses import dataclass


class DomainError(Exception):
    """A business rule was broken."""


class WipLimitReached(DomainError):
    """Too many open tasks for one project."""


@dataclass(frozen=True)
class Estimate:
    hours: float

    def __post_init__(self) -> None:
        if not 0 < self.hours <= 40:
            raise DomainError("an estimate must be above 0 and at most 40 hours")


class Task:
    def __init__(self, task_id: int, title: str, estimate: Estimate) -> None:
        self.id = task_id
        self.title = title
        self.estimate = estimate
        self.done = False

    def __eq__(self, other: object) -> bool:
        return isinstance(other, Task) and other.id == self.id

    def __hash__(self) -> int:
        return hash(self.id)


class Project:
    WIP_LIMIT = 3

    def __init__(self, project_id: int, name: str) -> None:
        self.id = project_id
        self.name = name
        self._tasks: list[Task] = []

    @property
    def open_tasks(self) -> list[Task]:
        return [task for task in self._tasks if not task.done]

    def open_hours(self) -> float:
        return sum(task.estimate.hours for task in self.open_tasks)

    def add_task(self, task: Task) -> None:
        if task in self._tasks:
            raise DomainError(f"task {task.id} already exists")
        if len(self.open_tasks) >= self.WIP_LIMIT:
            raise WipLimitReached(f"{self.name} already has {self.WIP_LIMIT} open tasks")
        self._tasks.append(task)

    def complete(self, task_id: int) -> None:
        for task in self._tasks:
            if task.id == task_id:
                task.done = True
                return
        raise DomainError(f"task {task_id} is not in {self.name}")
