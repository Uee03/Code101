import sqlite3
from datetime import datetime

from taskapp.domain import Task, TaskStatus

SCHEMA = """
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    completed_at TEXT
)
"""


class SqliteTaskRepository:
    def __init__(self, connection: sqlite3.Connection) -> None:
        self._connection = connection
        self._connection.execute(SCHEMA)

    def get(self, task_id: int) -> Task | None:
        row = self._connection.execute(
            "SELECT id, title, status, completed_at FROM tasks WHERE id = ?", (task_id,)
        ).fetchone()
        if row is None:
            return None
        completed = datetime.fromisoformat(row[3]) if row[3] else None
        return Task(row[0], row[1], TaskStatus(row[2]), completed)

    def save(self, task: Task) -> None:
        completed = task.completed_at.isoformat() if task.completed_at else None
        with self._connection:
            self._connection.execute(
                "INSERT INTO tasks (id, title, status, completed_at) VALUES (?, ?, ?, ?) "
                "ON CONFLICT(id) DO UPDATE SET title = excluded.title, "
                "status = excluded.status, completed_at = excluded.completed_at",
                (task.id, task.title, task.status.value, completed),
            )
