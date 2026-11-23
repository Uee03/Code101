from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Response

from app.access import team_access
from app.auth import AdminOnly, AdminWriter, Reader, Writer
from app.dependencies import AppSettings, Db
from app.http import IdempotencyKey, IfMatch, created, make_etag, parse_if_match, resource_url, to_json
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, SortCreated, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import teams
from app.repositories.sql import lock_and_check
from app.schemas import Page, Team, TeamCreate, TeamUpdate

router = APIRouter(prefix="/v1/teams", tags=["Teams"])


@router.get("", response_model=Page[Team])
def list_teams(principal: Reader, db: Db, q: Annotated[str | None, Query(min_length=1, max_length=100)] = None,
               sort: SortCreated = "-createdAt", limit: Limit = 25, cursor: Cursor = None) -> Page[Team]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        rows = teams.list_teams(conn, principal.user_id, principal.is_admin, q, sort == "-createdAt", limit + 1, after)
    return make_page(rows, limit, Team, lambda row: [row["created_at"], row["id"]])


@router.post("", response_model=Team, status_code=201)
def create_team(body: TeamCreate, principal: AdminWriter, db: Db, settings: AppSettings, idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", "/v1/teams", body)
    with db.transaction(principal.user_id) as conn:
        def create() -> dict:
            team_id = teams.create_team(conn, body.name, body.description, body.lead_user_id or principal.user_id, principal.user_id)
            return to_json(Team, teams.get_team(conn, team_id))

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/teams", data["id"]), replayed=replayed)


@router.get("/{team_id}", response_model=Team)
def get_team(team_id: UUID, response: Response, principal: Reader, db: Db) -> Team:
    with db.transaction() as conn:
        team_access(conn, principal, team_id)
        row = teams.get_team(conn, team_id)
    response.headers["ETag"] = make_etag(row["version"])
    return Team.model_validate(row)


@router.patch("/{team_id}", response_model=Team)
def update_team(team_id: UUID, body: TeamUpdate, response: Response, principal: Writer, db: Db, if_match: IfMatch = None) -> Team:
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("change the team")
        lock_and_check(conn, "teams", team_id, expected_version, "team")
        teams.update_team(conn, team_id, body.model_dump(exclude_unset=True))
        row = teams.get_team(conn, team_id)
    response.headers["ETag"] = make_etag(row["version"])
    return Team.model_validate(row)


@router.delete("/{team_id}", status_code=204)
def delete_team(team_id: UUID, principal: AdminOnly, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id)
        teams.delete_team(conn, team_id)
    return Response(status_code=204)
