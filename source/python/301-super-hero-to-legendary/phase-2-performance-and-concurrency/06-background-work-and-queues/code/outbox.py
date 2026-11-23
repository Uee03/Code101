import json
import sqlite3
from dataclasses import dataclass
from typing import Any

SCHEMA = """
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    done INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS outbox (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    payload TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    attempts INTEGER NOT NULL DEFAULT 0,
    available_at REAL NOT NULL,
    last_error TEXT
);
"""


@dataclass(frozen=True)
class Message:
    id: int
    topic: str
    payload: dict[str, Any]
    attempts: int


def connect(path: str = ":memory:") -> sqlite3.Connection:
    connection = sqlite3.connect(path)
    connection.executescript(SCHEMA)
    return connection


def complete_task(connection: sqlite3.Connection, task_id: int, now: float) -> None:
    with connection:
        cursor = connection.execute("UPDATE tasks SET done = 1 WHERE id = ? AND done = 0", (task_id,))
        if cursor.rowcount == 0:
            raise LookupError(f"task {task_id} is missing or already done")
        connection.execute(
            "INSERT INTO outbox (topic, payload, available_at) VALUES (?, ?, ?)",
            ("task.completed", json.dumps({"task_id": task_id}), now),
        )


def due_messages(connection: sqlite3.Connection, now: float, limit: int = 10) -> list[Message]:
    rows = connection.execute(
        "SELECT id, topic, payload, attempts FROM outbox "
        "WHERE status = 'pending' AND available_at <= ? ORDER BY id LIMIT ?",
        (now, limit),
    ).fetchall()
    return [Message(row[0], row[1], json.loads(row[2]), row[3]) for row in rows]


def mark_done(connection: sqlite3.Connection, message_id: int) -> None:
    with connection:
        connection.execute("UPDATE outbox SET status = 'done' WHERE id = ?", (message_id,))


def mark_retry(
    connection: sqlite3.Connection, message_id: int, attempts: int, available_at: float, error: str
) -> None:
    with connection:
        connection.execute(
            "UPDATE outbox SET attempts = ?, available_at = ?, last_error = ? WHERE id = ?",
            (attempts, available_at, error, message_id),
        )


def mark_dead(connection: sqlite3.Connection, message_id: int, attempts: int, error: str) -> None:
    with connection:
        connection.execute(
            "UPDATE outbox SET status = 'dead', attempts = ?, last_error = ? WHERE id = ?",
            (attempts, error, message_id),
        )


def backoff(attempts: int, base: float = 1.0, cap: float = 60.0) -> float:
    return min(cap, base * 2 ** (attempts - 1))


def count(connection: sqlite3.Connection, status: str | None = None) -> int:
    if status is None:
        return connection.execute("SELECT COUNT(*) FROM outbox").fetchone()[0]
    return connection.execute("SELECT COUNT(*) FROM outbox WHERE status = ?", (status,)).fetchone()[0]
