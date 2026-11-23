from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one

COMMENT_SELECT = """
    SELECT c.id, c.task_id, c.body, c.created_at,
           u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name
      FROM comments c JOIN users u ON u.id = c.author_id
"""


def shape(row: Row) -> Row:
    """Nest the author columns the way the Comment DTO expects them."""
    return {
        "id": row["id"], "task_id": row["task_id"], "body": row["body"], "created_at": row["created_at"],
        "author": {"id": row["author_id"], "username": row["author_username"], "display_name": row["author_display_name"]},
    }


def list_comments(conn: Connection, task_id: UUID, limit: int, after: list[Any] | None) -> list[Row]:
    rows = fetch_all(
        conn,
        COMMENT_SELECT + """
        WHERE c.task_id = :task_id
          AND (CAST(:after_created AS timestamptz) IS NULL
               OR (c.created_at, c.id) > (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid)))
        ORDER BY c.created_at, c.id
        LIMIT :limit
        """,
        {"task_id": task_id, "after_created": after[0] if after else None, "after_id": after[1] if after else None, "limit": limit},
    )
    return [shape(row) for row in rows]


def get_comment(conn: Connection, comment_id: UUID) -> Row | None:
    row = fetch_one(conn, COMMENT_SELECT + " WHERE c.id = :id", {"id": comment_id})
    return None if row is None else shape(row)


def get_owner(conn: Connection, comment_id: UUID) -> Row | None:
    """Who wrote the comment and which team it belongs to: the two facts the delete rule needs."""
    return fetch_one(
        conn,
        "SELECT c.author_id, p.team_id FROM comments c JOIN tasks t ON t.id = c.task_id "
        "JOIN projects p ON p.id = t.project_id WHERE c.id = :id",
        {"id": comment_id},
    )


def create_comment(conn: Connection, task_id: UUID, author_id: UUID, body: str) -> UUID:
    return conn.execute(
        text("INSERT INTO comments (task_id, author_id, body) VALUES (:task_id, :author_id, :body) RETURNING id"),
        {"task_id": task_id, "author_id": author_id, "body": body},
    ).scalar_one()


def delete_comment(conn: Connection, comment_id: UUID) -> None:
    conn.execute(text("DELETE FROM comments WHERE id = :id"), {"id": comment_id})
