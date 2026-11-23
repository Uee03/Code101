from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one


def ensure_user(conn: Connection, user_id: UUID, username: str, email: str, display_name: str) -> None:
    """First sight of a Keycloak user: store the row the foreign keys point to. Existing rows stay untouched."""
    conn.execute(
        text("INSERT INTO users (id, username, email, display_name) VALUES (:id, :username, :email, :display_name) "
             "ON CONFLICT DO NOTHING"),
        {"id": user_id, "username": username, "email": email, "display_name": display_name},
    )


def get_user(conn: Connection, user_id: UUID) -> Row | None:
    return fetch_one(conn, "SELECT id, username, email, display_name FROM users WHERE id = :id", {"id": user_id})


def list_users(conn: Connection, prefix: str | None, limit: int, after: list[Any] | None) -> list[Row]:
    return fetch_all(
        conn,
        """
        SELECT id, username, display_name FROM users
        WHERE (CAST(:prefix AS text) IS NULL
               OR starts_with(lower(username), lower(:prefix)) OR starts_with(lower(display_name), lower(:prefix)))
          AND (CAST(:after_name AS text) IS NULL OR (username, id) > (CAST(:after_name AS text), CAST(:after_id AS uuid)))
        ORDER BY username, id
        LIMIT :limit
        """,
        {"prefix": prefix, "after_name": after[0] if after else None, "after_id": after[1] if after else None, "limit": limit},
    )
