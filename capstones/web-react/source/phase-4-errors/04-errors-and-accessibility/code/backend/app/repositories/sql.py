from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.errors import ProblemError, not_found

Row = dict[str, Any]


def fetch_one(conn: Connection, sql: str, params: dict[str, Any]) -> Row | None:
    row = conn.execute(text(sql), params).mappings().first()
    return dict(row) if row is not None else None


def fetch_all(conn: Connection, sql: str, params: dict[str, Any]) -> list[Row]:
    return [dict(row) for row in conn.execute(text(sql), params).mappings().all()]


def like_escape(value: str) -> str:
    """Make %, _ and the backslash itself match literally inside a LIKE pattern (used with ESCAPE '\\')."""
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def lock_and_check(conn: Connection, table: str, row_id: UUID, expected_version: int | None, label: str) -> None:
    """Lock the row until the transaction ends, then compare its version with the caller's If-Match.

    `table` is always a literal from our own code, never a request value.
    """
    current = conn.execute(text(f"SELECT version FROM {table} WHERE id = :id FOR UPDATE"), {"id": row_id}).scalar()
    if current is None:
        raise not_found()
    if expected_version is not None and current != expected_version:
        raise ProblemError(412, f"The {label} changed since you read it (current version {current}).")


def update_columns(conn: Connection, table: str, row_id: UUID, changes: dict[str, Any], allowed: frozenset[str]) -> None:
    """UPDATE only the named columns. Column names are checked against an allow-list; values are always bound."""
    unknown = set(changes) - allowed
    if unknown:
        raise ValueError(f"column not allowed: {sorted(unknown)}")
    if not changes:
        return
    assignments = ", ".join(f"{column} = :{column}" for column in changes)
    conn.execute(text(f"UPDATE {table} SET {assignments} WHERE id = :id"), {**changes, "id": row_id})
