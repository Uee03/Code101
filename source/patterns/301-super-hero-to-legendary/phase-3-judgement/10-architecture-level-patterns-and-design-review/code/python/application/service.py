from application.ports import TaskStore
from domain.task import Task


class TaskService:
    def __init__(self, store: TaskStore):
        self._store = store

    def complete(self, task_id) -> Task:
        task = self._store.get(task_id)
        task.complete()
        self._store.save(task)
        return task
