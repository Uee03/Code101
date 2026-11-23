from taskapp.domain import DomainError, Task
from taskapp.ports import Clock, Notifier, TaskRepository


class TaskNotFound(DomainError):
    pass


class CompleteTask:
    def __init__(self, tasks: TaskRepository, clock: Clock, notifier: Notifier) -> None:
        self._tasks = tasks
        self._clock = clock
        self._notifier = notifier

    def __call__(self, task_id: int) -> Task:
        task = self._tasks.get(task_id)
        if task is None:
            raise TaskNotFound(f"task {task_id} was not found")
        done = task.complete(self._clock.now())
        self._tasks.save(done)
        self._notifier.task_completed(done)
        return done
