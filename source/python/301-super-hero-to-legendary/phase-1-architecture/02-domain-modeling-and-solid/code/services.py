from domain import DomainError, Estimate, Task
from ports import UnitOfWork


def add_task(uow: UnitOfWork, project_id: int, task_id: int, title: str, hours: float) -> None:
    with uow:
        project = uow.projects.get(project_id)
        if project is None:
            raise DomainError(f"project {project_id} not found")
        project.add_task(Task(task_id, title, Estimate(hours)))
        uow.commit()
