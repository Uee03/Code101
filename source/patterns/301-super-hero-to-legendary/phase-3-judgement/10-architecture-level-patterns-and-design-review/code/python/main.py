from pathlib import Path

from adapters.console import render
from adapters.memory_repo import InMemoryTaskStore
from application.service import TaskService
from check_architecture import check_source, check_tree
from domain.task import Task


def main():
    store = InMemoryTaskStore([Task(1, "Write ADR")])
    service = TaskService(store)
    print(render(service.complete(1)))

    files, problems = check_tree(Path(__file__).parent)
    print(f"architecture check: {files} files, {len(problems)} violations")
    bad = check_source("domain", "from adapters.memory_repo import InMemoryTaskStore")
    print(f"bad snippet: {bad[0]}")


main()
