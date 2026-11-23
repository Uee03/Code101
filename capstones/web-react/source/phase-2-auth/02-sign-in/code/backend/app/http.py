import re
from typing import Annotated, Any
from uuid import UUID

from fastapi import Header
from fastapi.responses import JSONResponse

from app.config import Settings
from app.errors import ProblemError, bad_request
from app.schemas import ApiModel

IfMatch = Annotated[str | None, Header(description='The ETag being changed, for example "3".')]
IdempotencyKey = Annotated[str | None, Header(min_length=8, max_length=128)]


def make_etag(version: int) -> str:
    return f'"{version}"'


def parse_if_match(value: str | None, *, required: bool = True) -> int | None:
    """Read the version out of one strong ETag. A missing header is 428; anything else that is not an ETag is 400."""
    if value is None:
        if required:
            raise ProblemError(428, "The If-Match header is required. Read the resource first and send its ETag.")
        return None
    match = re.fullmatch(r'"(\d{1,9})"', value.strip())
    if match is None:
        raise bad_request('If-Match must be one strong ETag such as "3".')
    return int(match.group(1))


def etag_matches(if_none_match: str | None, version: int) -> bool:
    """If-None-Match uses the weak comparison: W/"3" matches "3"; * matches any existing resource."""
    if if_none_match is None:
        return False
    candidates = [part.strip().removeprefix("W/") for part in if_none_match.split(",")]
    return "*" in candidates or make_etag(version) in candidates


def resource_url(settings: Settings, path: str, resource_id: UUID | str) -> str:
    return f"{settings.public_base_url.rstrip('/')}{path}/{resource_id}"


def to_json(model: type[ApiModel], row: dict[str, Any]) -> dict[str, Any]:
    """A database row as the JSON body of the API (camelCase, dates as text). This is what idempotency stores."""
    return model.model_validate(row).model_dump(mode="json", by_alias=True)


def json_with_etag(model: type[ApiModel], row: dict[str, Any]) -> JSONResponse:
    """200 with the resource as JSON and its ETag (the quoted version)."""
    return JSONResponse(to_json(model, row), headers={"ETag": make_etag(row["version"])})


def created(body: dict[str, Any], location: str, *, replayed: bool = False) -> JSONResponse:
    """201 with Location and ETag; a replay of an Idempotency-Key adds Idempotent-Replayed: true."""
    headers = {"Location": location}
    if "version" in body:
        headers["ETag"] = make_etag(body["version"])
    if replayed:
        headers["Idempotent-Replayed"] = "true"
    return JSONResponse(body, status_code=201, headers=headers)
