from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one, like_escape, update_columns

TEAM_SELECT = """
    SELECT t.id, t.name, t.description, t.created_by, t.version, t.created_at, t.updated_at,
           (SELECT count(*) FROM team_members m WHERE m.team_id = t.id) AS member_count
      FROM teams t
"""


def get_team(conn: Connection, team_id: UUID) -> Row | None:
    return fetch_one(conn, TEAM_SELECT + " WHERE t.id = :id", {"id": team_id})


def get_access(conn: Connection, team_id: UUID, user_id: UUID) -> Row | None:
    """None when the team does not exist; otherwise the caller's team role (None when the caller is not a member)."""
    return fetch_one(
        conn,
        "SELECT t.id, m.role FROM teams t LEFT JOIN team_members m ON m.team_id = t.id AND m.user_id = :user_id "
        "WHERE t.id = :team_id",
        {"team_id": team_id, "user_id": user_id},
    )


def list_teams(conn: Connection, user_id: UUID, all_teams: bool, prefix: str | None, newest_first: bool,
               limit: int, after: list[Any] | None) -> list[Row]:
    """Keyset pagination: continue after the (created_at, id) pair of the last row of the previous page."""
    comparison, direction = ("<", "DESC") if newest_first else (">", "ASC")
    return fetch_all(
        conn,
        TEAM_SELECT + f"""
        WHERE (:all_teams OR EXISTS (SELECT 1 FROM team_members m WHERE m.team_id = t.id AND m.user_id = :user_id))
          AND (CAST(:prefix AS text) IS NULL OR lower(t.name) LIKE :pattern ESCAPE '\\')
          AND (CAST(:after_created AS timestamptz) IS NULL
               OR (t.created_at, t.id) {comparison} (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid)))
        ORDER BY t.created_at {direction}, t.id {direction}
        LIMIT :limit
        """,
        {
            "all_teams": all_teams,
            "user_id": user_id,
            "prefix": prefix,
            "pattern": like_escape(prefix.lower()) + "%" if prefix else None,
            "after_created": after[0] if after else None,
            "after_id": after[1] if after else None,
            "limit": limit,
        },
    )


def create_team(conn: Connection, name: str, description: str, lead_id: UUID, actor_id: UUID) -> UUID:
    """The stored function inserts the team and its first lead in one step (and sets the audit actor)."""
    return conn.execute(
        text("SELECT id FROM create_team(:name, :description, :lead_id, :actor_id)"),
        {"name": name, "description": description, "lead_id": lead_id, "actor_id": actor_id},
    ).scalar_one()


def update_team(conn: Connection, team_id: UUID, changes: dict[str, Any]) -> None:
    update_columns(conn, "teams", team_id, changes, frozenset({"name", "description"}))


def delete_team(conn: Connection, team_id: UUID) -> None:
    conn.execute(text("DELETE FROM teams WHERE id = :id"), {"id": team_id})
