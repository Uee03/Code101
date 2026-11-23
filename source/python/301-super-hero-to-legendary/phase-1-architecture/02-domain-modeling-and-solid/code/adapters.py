import copy
from types import TracebackType
from typing import Self

from domain import Project


class InMemoryProjectRepository:
    def __init__(self, store: dict[int, Project]) -> None:
        self._store = store

    def get(self, project_id: int) -> Project | None:
        return self._store.get(project_id)

    def add(self, project: Project) -> None:
        self._store[project.id] = project


class InMemoryUnitOfWork:
    def __init__(self, committed: dict[int, Project]) -> None:
        self._committed = committed
        self._working: dict[int, Project] = {}
        self.projects = InMemoryProjectRepository(self._working)
        self.commits = 0

    def __enter__(self) -> Self:
        self._working = copy.deepcopy(self._committed)
        self.projects = InMemoryProjectRepository(self._working)
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        self._working = {}
        self.projects = InMemoryProjectRepository(self._working)

    def commit(self) -> None:
        self._committed.clear()
        self._committed.update(self._working)
        self.commits += 1
