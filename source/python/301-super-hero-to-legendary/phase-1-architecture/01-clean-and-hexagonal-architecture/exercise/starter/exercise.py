from dataclasses import dataclass, replace
from typing import Protocol


@dataclass(frozen=True)
class Task:
    id: int
    title: str
    done: bool = False


class TaskRepository(Protocol):
    def get(self, task_id: int) -> Task | None: ...

    def save(self, task: Task) -> None: ...


class InMemoryTaskRepository:
    def __init__(self, tasks: list[Task]) -> None:
        self._tasks = {task.id: task for task in tasks}

    def get(self, task_id: int) -> Task | None:
        return self._tasks.get(task_id)

    def save(self, task: Task) -> None:
        self._tasks[task.id] = task


class ReopenTask:
    def __init__(self, tasks: TaskRepository) -> None:
        self._tasks = tasks

    def __call__(self, task_id: int) -> Task:
        # TODO 1: load the task; raise LookupError(f"task {task_id} was not found") when it is missing
        # TODO 2: raise ValueError(f"task {task_id} is not done") when it is still open
        # TODO 3: save and return a copy of the task with done=False (use replace)
        raise NotImplementedError


if __name__ == "__main__":
    repository = InMemoryTaskRepository([Task(1, "Write the report", done=True), Task(2, "Plan the week")])
    reopen = ReopenTask(repository)
    print(reopen(1))
    for missing_or_open in (2, 9):
        try:
            reopen(missing_or_open)
        except (LookupError, ValueError) as error:
            print(error)
