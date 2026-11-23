from datetime import date
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one, like_escape, update_columns

TASK_SELECT = """
    SELECT t.id, t.project_id, t.title, t.description, t.status, t.priority, t.assignee_id, t.due_date,
           t.completed_at, t.created_by, t.version, t.created_at, t.updated_at, p.team_id
      FROM tasks t JOIN projects p ON p.id = t.project_id
"""
TASK_COLUMNS = ("id, project_id, title, description, status, priority, assignee_id, due_date, "
                "completed_at, created_by, version, created_at, updated_at")


def get_task(conn: Connection, task_id: UUID) -> Row | None:
    """The row carries team_id as well (not part of the API), so the caller can check team access."""
    return fetch_one(conn, TASK_SELECT + " WHERE t.id = :id", {"id": task_id})


def list_tasks(conn: Connection, project_id: UUID, *, statuses: list[str], priorities: list[str], assignee_id: UUID | None,
               due_before: date | None, due_after: date | None, title_contains: str | None, sort: str,
               limit: int, after: list[Any] | None) -> list[Row]:
    """Every filter is optional; a filter that is not used is switched off by its NULL parameter."""
    keyset, order = KEYSETS[sort]
    return fetch_all(
        conn,
        TASK_SELECT + f"""
        WHERE t.project_id = :project_id
          AND (cardinality(CAST(:statuses AS text[])) = 0 OR t.status = ANY(CAST(:statuses AS text[])))
          AND (cardinality(CAST(:priorities AS text[])) = 0 OR t.priority = ANY(CAST(:priorities AS text[])))
          AND (CAST(:assignee_id AS uuid) IS NULL OR t.assignee_id = CAST(:assignee_id AS uuid))
          AND (CAST(:due_before AS date) IS NULL OR t.due_date <= CAST(:due_before AS date))
          AND (CAST(:due_after AS date) IS NULL OR t.due_date >= CAST(:due_after AS date))
          AND (CAST(:pattern AS text) IS NULL OR t.title ILIKE :pattern ESCAPE '\\')
          AND ({keyset})
        ORDER BY {order}
        LIMIT :limit
        """,
        {
            "project_id": project_id,
            "statuses": statuses,
            "priorities": priorities,
            "assignee_id": assignee_id,
            "due_before": due_before,
            "due_after": due_after,
            "pattern": f"%{like_escape(title_contains)}%" if title_contains else None,
            "after_created": after[0] if after and sort != "dueDate" else None,
            "after_due": after[0] if after and sort == "dueDate" else None,
            "after_id": after[1] if after else None,
            "after_given": after is not None,
            "limit": limit,
        },
    )


# sort value -> (condition that skips everything up to the cursor, ORDER BY). Ties always break on id.
KEYSETS = {
    "-createdAt": (
        "NOT :after_given OR (t.created_at, t.id) < (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid))",
        "t.created_at DESC, t.id DESC",
    ),
    "createdAt": (
        "NOT :after_given OR (t.created_at, t.id) > (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid))",
        "t.created_at ASC, t.id ASC",
    ),
    "dueDate": (
        """NOT :after_given
           OR (CAST(:after_due AS date) IS NOT NULL
               AND (t.due_date > CAST(:after_due AS date)
                    OR (t.due_date = CAST(:after_due AS date) AND t.id > CAST(:after_id AS uuid))
                    OR t.due_date IS NULL))
           OR (CAST(:after_due AS date) IS NULL AND t.due_date IS NULL AND t.id > CAST(:after_id AS uuid))""",
        "t.due_date ASC NULLS LAST, t.id ASC",
    ),
}


def create_task(conn: Connection, project_id: UUID, title: str, description: str, priority: str,
                assignee_id: UUID | None, due_date: date | None, actor_id: UUID) -> Row:
    row = fetch_one(
        conn,
        f"INSERT INTO tasks (project_id, title, description, priority, assignee_id, due_date, created_by) "
        f"VALUES (:project_id, :title, :description, :priority, :assignee_id, :due_date, :actor_id) RETURNING {TASK_COLUMNS}",
        {"project_id": project_id, "title": title, "description": description, "priority": priority,
         "assignee_id": assignee_id, "due_date": due_date, "actor_id": actor_id},
    )
    assert row is not None
    return row


def update_task(conn: Connection, task_id: UUID, changes: dict[str, Any]) -> None:
    update_columns(conn, "tasks", task_id, changes,
                   frozenset({"title", "description", "status", "priority", "assignee_id", "due_date"}))


def delete_task(conn: Connection, task_id: UUID) -> None:
    conn.execute(text("DELETE FROM tasks WHERE id = :id"), {"id": task_id})


def complete_task(conn: Connection, task_id: UUID, actor_id: UUID, expected_version: int) -> None:
    """The stored function locks the row, checks the version and the rules, and sets status done in one step."""
    conn.execute(text("SELECT id FROM complete_task(:task_id, :actor_id, :version)"),
                 {"task_id": task_id, "actor_id": actor_id, "version": expected_version})


def reassign_task(conn: Connection, task_id: UUID, assignee_id: UUID | None, actor_id: UUID, expected_version: int) -> None:
    conn.execute(text("SELECT id FROM reassign_task(:task_id, :assignee_id, :actor_id, :version)"),
                 {"task_id": task_id, "assignee_id": assignee_id, "actor_id": actor_id, "version": expected_version})
