from typing import Annotated

from fastapi import APIRouter, Query

from app.auth import Reader
from app.dependencies import Db
from app.pagination import Cursor, Limit, as_text, as_uuid, decode_cursor, make_page
from app.repositories import users
from app.schemas import Page, UserSummary

router = APIRouter(prefix="/v1/users", tags=["Platform"])


@router.get("", response_model=Page[UserSummary])
def list_users(principal: Reader, db: Db, q: Annotated[str | None, Query(min_length=1, max_length=100)] = None,
               limit: Limit = 25, cursor: Cursor = None) -> Page[UserSummary]:
    after = decode_cursor(cursor, [as_text, as_uuid]) if cursor else None
    with db.transaction() as conn:
        rows = users.list_users(conn, q, limit + 1, after)
    return make_page(rows, limit, UserSummary, lambda row: [row["username"], row["id"]])
