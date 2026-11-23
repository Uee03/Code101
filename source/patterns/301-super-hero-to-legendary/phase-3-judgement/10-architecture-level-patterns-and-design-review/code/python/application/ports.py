from abc import ABC, abstractmethod

from domain.task import Task


class TaskStore(ABC):
    @abstractmethod
    def get(self, task_id) -> Task:
        ...

    @abstractmethod
    def save(self, task: Task) -> None:
        ...
