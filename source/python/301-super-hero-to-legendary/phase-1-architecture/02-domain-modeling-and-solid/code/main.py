from adapters import InMemoryUnitOfWork
from domain import DomainError, Project
from services import add_task


def main() -> None:
    committed = {1: Project(1, "Launch")}
    uow = InMemoryUnitOfWork(committed)
    for task_id in range(1, 5):
        try:
            add_task(uow, 1, task_id, f"Task {task_id}", 4.0)
            print(f"added task {task_id}")
        except DomainError as error:
            print(f"refused task {task_id}: {error}")
    project = committed[1]
    print(f"open: {[task.id for task in project.open_tasks]}, hours: {project.open_hours()}, commits: {uow.commits}")


if __name__ == "__main__":
    main()
