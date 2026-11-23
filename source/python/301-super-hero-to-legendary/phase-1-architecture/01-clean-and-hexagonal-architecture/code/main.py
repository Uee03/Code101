import sqlite3
from datetime import datetime, timezone

from taskapp.adapters.memory import FixedClock, InMemoryTaskRepository, RecordingNotifier
from taskapp.adapters.sqlite_repo import SqliteTaskRepository
from taskapp.domain import Task
from taskapp.ports import TaskRepository
from taskapp.use_cases import CompleteTask


def run(label: str, repository: TaskRepository) -> None:
    notifier = RecordingNotifier()
    clock = FixedClock(datetime(2026, 1, 15, 9, 30, tzinfo=timezone.utc))
    complete = CompleteTask(repository, clock, notifier)
    done = complete(1)
    print(f"{label}: {done.title} -> {done.status.value} at {done.completed_at.isoformat()}")
    print(f"{label}: notified {notifier.completed}")


def main() -> None:
    seed = Task(1, "Write the report")
    run("memory", InMemoryTaskRepository([seed]))
    sqlite_repository = SqliteTaskRepository(sqlite3.connect(":memory:"))
    sqlite_repository.save(seed)
    run("sqlite", sqlite_repository)
    print("persisted:", sqlite_repository.get(1).status.value)


if __name__ == "__main__":
    main()
