from uuid import UUID

from fastapi import APIRouter, Response

from app.access import team_access
from app.auth import Reader, Writer
from app.dependencies import Db
from app.errors import conflict, not_found
from app.pagination import Cursor, Limit, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import members, users
from app.schemas import Member, MemberPut, Page

router = APIRouter(prefix="/v1/teams/{team_id}/members", tags=["Members"])


@router.get("", response_model=Page[Member])
def list_members(team_id: UUID, principal: Reader, db: Db, limit: Limit = 25, cursor: Cursor = None) -> Page[Member]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        team_access(conn, principal, team_id)
        rows = members.list_members(conn, team_id, limit + 1, after)
    return make_page(rows, limit, Member, lambda row: [row["joined_at"], row["user_id"]])


@router.put("/{user_id}", response_model=Member)
def put_member(team_id: UUID, user_id: UUID, body: MemberPut, response: Response, principal: Writer, db: Db) -> Member:
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("manage members")
        if users.get_user(conn, user_id) is None:
            raise not_found("The user was not found.")
        if body.role != "lead" and members.lock_leads(conn, team_id) == [user_id]:
            raise conflict("A team needs at least one lead.", code="last_lead")
        inserted = members.put_member(conn, team_id, user_id, body.role)
        row = members.get_member(conn, team_id, user_id)
    response.status_code = 201 if inserted else 200
    return Member.model_validate(row)


@router.delete("/{user_id}", status_code=204)
def remove_member(team_id: UUID, user_id: UUID, principal: Writer, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("manage members")
        if members.get_member(conn, team_id, user_id) is None:
            raise not_found("The user is not a member of this team.")
        if members.lock_leads(conn, team_id) == [user_id]:
            raise conflict("The last lead cannot be removed.", code="last_lead")
        members.delete_member(conn, team_id, user_id)
    return Response(status_code=204)
