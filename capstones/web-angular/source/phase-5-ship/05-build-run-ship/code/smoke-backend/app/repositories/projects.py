from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one, update_columns

PROJECT_COLUMNS = "id, team_id, key, name, description, archived, version, created_at, updated_at"


def get_project(conn: Connection, project_id: UUID) -> Row | None:
    return fetch_one(conn, f"SELECT {PROJECT_COLUMNS} FROM projects WHERE id = :id", {"id": project_id})


def list_projects(conn: Connection, team_id: UUID, archived: bool, newest_first: bool, limit: int,
                  after: list[Any] | None) -> list[Row]:
    comparison, direction = ("<", "DESC") if newest_first else (">", "ASC")
    return fetch_all(
        conn,
        f"""
        SELECT {PROJECT_COLUMNS} FROM projects
         WHERE team_id = :team_id AND archived = :archived
           AND (CAST(:after_created AS timestamptz) IS NULL
                OR (created_at, id) {comparison} (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid)))
         ORDER BY created_at {direction}, id {direction}
         LIMIT :limit
        """,
        {"team_id": team_id, "archived": archived, "after_created": after[0] if after else None,
         "after_id": after[1] if after else None, "limit": limit},
    )


def create_project(conn: Connection, team_id: UUID, key: str, name: str, description: str, actor_id: UUID) -> Row:
    row = fetch_one(
        conn,
        f"INSERT INTO projects (team_id, key, name, description, created_by) "
        f"VALUES (:team_id, :key, :name, :description, :actor_id) RETURNING {PROJECT_COLUMNS}",
        {"team_id": team_id, "key": key, "name": name, "description": description, "actor_id": actor_id},
    )
    assert row is not None
    return row


def update_project(conn: Connection, project_id: UUID, changes: dict[str, Any]) -> None:
    update_columns(conn, "projects", project_id, changes, frozenset({"name", "description", "archived"}))


def delete_project(conn: Connection, project_id: UUID) -> None:
    conn.execute(text("DELETE FROM projects WHERE id = :id"), {"id": project_id})
