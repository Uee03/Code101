import base64
import json
from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Any, Literal
from uuid import UUID

from fastapi import Query

from app.errors import bad_request
from app.schemas import Page, PageInfo

Limit = Annotated[int, Query(ge=1, le=100, description="Page size.")]
Cursor = Annotated[str | None, Query(min_length=1, max_length=512, description="Copied from page.nextCursor.")]
SortCreated = Annotated[Literal["-createdAt", "createdAt"], Query()]


def encode_cursor(values: list[Any]) -> str:
    """The values that identify the last row on the page, as JSON, then base64url without padding."""
    raw = json.dumps([v.isoformat() if isinstance(v, (date, datetime)) else str(v) if isinstance(v, UUID) else v
                      for v in values], separators=(",", ":"))
    return base64.urlsafe_b64encode(raw.encode()).rstrip(b"=").decode()


def decode_cursor(cursor: str, parsers: list[Callable[[Any], Any]]) -> list[Any]:
    """Parse and check every value; any failure is the client's fault, so it becomes a 400."""
    try:
        values = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
        if not isinstance(values, list) or len(values) != len(parsers):
            raise ValueError("wrong shape")
        return [parse(value) for parse, value in zip(parsers, values)]
    except (ValueError, TypeError, AttributeError):
        raise bad_request("The cursor is not valid.") from None


def as_timestamp(value: Any) -> datetime:
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        raise ValueError("timestamp without a zone")
    return parsed


def as_uuid(value: Any) -> UUID:
    if not isinstance(value, str):
        raise ValueError("not a string")
    return UUID(value)


def as_text(value: Any) -> str:
    if not isinstance(value, str):
        raise ValueError("not a string")
    return value


def as_int(value: Any) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError("not an integer")
    return value


def as_optional_date(value: Any) -> date | None:
    return None if value is None else date.fromisoformat(value)


def make_page[T](rows: list[dict[str, Any]], limit: int, model: type[T], cursor_of: Callable[[dict[str, Any]], list[Any]]) -> Page[T]:
    """Queries fetch limit + 1 rows: the extra row only proves that another page exists."""
    items = rows[:limit]
    next_cursor = encode_cursor(cursor_of(items[-1])) if len(rows) > limit else None
    return Page[model](items=[model.model_validate(row) for row in items], page=PageInfo(limit=limit, next_cursor=next_cursor))
