from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one


def get_membership(conn: Connection, team_id: UUID, user_id: UUID) -> str | None:
    """The team role of a user ('lead' or 'member'), or None when the user is not in the team."""
    return conn.execute(
        text("SELECT role FROM team_members WHERE team_id = :team_id AND user_id = :user_id"),
        {"team_id": team_id, "user_id": user_id},
    ).scalar()


def teams_of(conn: Connection, user_id: UUID) -> list[Row]:
    return fetch_all(
        conn,
        "SELECT t.id AS team_id, t.name, m.role FROM team_members m JOIN teams t ON t.id = m.team_id "
        "WHERE m.user_id = :user_id ORDER BY t.name",
        {"user_id": user_id},
    )


def list_members(conn: Connection, team_id: UUID, limit: int, after: list[Any] | None) -> list[Row]:
    return fetch_all(
        conn,
        """
        SELECT m.user_id, u.username, u.display_name, m.role, m.joined_at
          FROM team_members m JOIN users u ON u.id = m.user_id
         WHERE m.team_id = :team_id
           AND (CAST(:after_joined AS timestamptz) IS NULL
                OR (m.joined_at, m.user_id) > (CAST(:after_joined AS timestamptz), CAST(:after_id AS uuid)))
         ORDER BY m.joined_at, m.user_id
         LIMIT :limit
        """,
        {"team_id": team_id, "after_joined": after[0] if after else None, "after_id": after[1] if after else None, "limit": limit},
    )


def get_member(conn: Connection, team_id: UUID, user_id: UUID) -> Row | None:
    return fetch_one(
        conn,
        "SELECT m.user_id, u.username, u.display_name, m.role, m.joined_at "
        "FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = :team_id AND m.user_id = :user_id",
        {"team_id": team_id, "user_id": user_id},
    )


def lock_leads(conn: Connection, team_id: UUID) -> list[UUID]:
    """Lock the lead rows so two requests cannot remove the last two leads at the same time."""
    rows = conn.execute(
        text("SELECT user_id FROM team_members WHERE team_id = :team_id AND role = 'lead' FOR UPDATE"),
        {"team_id": team_id},
    )
    return [row[0] for row in rows]


def put_member(conn: Connection, team_id: UUID, user_id: UUID, role: str) -> bool:
    """Insert or change the role. Returns True when the member is new (xmax is 0 only for a fresh row)."""
    return conn.execute(
        text("INSERT INTO team_members (team_id, user_id, role) VALUES (:team_id, :user_id, :role) "
             "ON CONFLICT (team_id, user_id) DO UPDATE SET role = EXCLUDED.role RETURNING (xmax = 0)"),
        {"team_id": team_id, "user_id": user_id, "role": role},
    ).scalar_one()


def delete_member(conn: Connection, team_id: UUID, user_id: UUID) -> None:
    conn.execute(text("DELETE FROM team_members WHERE team_id = :team_id AND user_id = :user_id"),
                 {"team_id": team_id, "user_id": user_id})
