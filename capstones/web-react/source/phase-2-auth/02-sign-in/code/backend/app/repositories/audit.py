from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection

from app.repositories.sql import Row, fetch_all


def list_audit(conn: Connection, *, entity_type: str | None, entity_id: UUID | None, actor_id: UUID | None,
               occurred_from: datetime | None, occurred_to: datetime | None, limit: int, after: list[Any] | None) -> list[Row]:
    """Newest first. The cursor is (occurred_at, id) of the last entry on the previous page."""
    return fetch_all(
        conn,
        """
        SELECT id, occurred_at, actor_id, action, entity_type, entity_id, details
          FROM audit_log
         WHERE (CAST(:entity_type AS text) IS NULL OR entity_type = :entity_type)
           AND (CAST(:entity_id AS uuid) IS NULL OR entity_id = CAST(:entity_id AS uuid))
           AND (CAST(:actor_id AS uuid) IS NULL OR actor_id = CAST(:actor_id AS uuid))
           AND (CAST(:occurred_from AS timestamptz) IS NULL OR occurred_at >= CAST(:occurred_from AS timestamptz))
           AND (CAST(:occurred_to AS timestamptz) IS NULL OR occurred_at < CAST(:occurred_to AS timestamptz))
           AND (CAST(:after_occurred AS timestamptz) IS NULL
                OR (occurred_at, id) < (CAST(:after_occurred AS timestamptz), CAST(:after_id AS bigint)))
         ORDER BY occurred_at DESC, id DESC
         LIMIT :limit
        """,
        {
            "entity_type": entity_type,
            "entity_id": entity_id,
            "actor_id": actor_id,
            "occurred_from": occurred_from,
            "occurred_to": occurred_to,
            "after_occurred": after[0] if after else None,
            "after_id": after[1] if after else None,
            "limit": limit,
        },
    )
