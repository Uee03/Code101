from application.ports import TaskStore
from domain.task import Task


class InMemoryTaskStore(TaskStore):
    def __init__(self, tasks):
        self._tasks = {t.id: t for t in tasks}

    def get(self, task_id) -> Task:
        return self._tasks[task_id]

    def save(self, task: Task) -> None:
        self._tasks[task.id] = task
