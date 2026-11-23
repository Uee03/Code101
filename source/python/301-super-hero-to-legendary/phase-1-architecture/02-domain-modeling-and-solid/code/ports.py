from types import TracebackType
from typing import Protocol, Self

from domain import Project


class ProjectRepository(Protocol):
    def get(self, project_id: int) -> Project | None: ...

    def add(self, project: Project) -> None: ...


class UnitOfWork(Protocol):
    projects: ProjectRepository

    def __enter__(self) -> Self: ...

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> None: ...

    def commit(self) -> None: ...
