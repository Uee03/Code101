from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query

from app.auth import AdminOnly
from app.dependencies import Db
from app.pagination import Cursor, Limit, as_int, as_timestamp, decode_cursor, make_page
from app.repositories import audit
from app.schemas import AuditEntityType, AuditEntry, Page

router = APIRouter(prefix="/v1/audit-log", tags=["Audit"])


@router.get("", response_model=Page[AuditEntry])
def list_audit_log(
    principal: AdminOnly, db: Db,
    entity_type: Annotated[AuditEntityType | None, Query(alias="entityType")] = None,
    entity_id: Annotated[UUID | None, Query(alias="entityId")] = None,
    actor_id: Annotated[UUID | None, Query(alias="actorId")] = None,
    occurred_from: Annotated[datetime | None, Query(alias="from")] = None,
    occurred_to: Annotated[datetime | None, Query(alias="to")] = None,
    limit: Limit = 25, cursor: Cursor = None,
) -> Page[AuditEntry]:
    after = decode_cursor(cursor, [as_timestamp, as_int]) if cursor else None
    with db.transaction() as conn:
        rows = audit.list_audit(conn, entity_type=entity_type, entity_id=entity_id, actor_id=actor_id,
                                occurred_from=occurred_from, occurred_to=occurred_to, limit=limit + 1, after=after)
    return make_page(rows, limit, AuditEntry, lambda row: [row["occurred_at"], row["id"]])
