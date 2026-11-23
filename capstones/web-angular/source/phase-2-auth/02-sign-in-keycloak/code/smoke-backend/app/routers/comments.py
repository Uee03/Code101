from uuid import UUID

from fastapi import APIRouter, Response

from app.access import comment_access, task_access
from app.auth import Reader, Writer
from app.dependencies import AppSettings, Db
from app.errors import forbidden
from app.http import IdempotencyKey, created, resource_url, to_json
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import comments
from app.schemas import Comment, CommentCreate, Page

router = APIRouter(tags=["Comments"])


@router.get("/v1/tasks/{task_id}/comments", response_model=Page[Comment])
def list_comments(task_id: UUID, principal: Reader, db: Db, limit: Limit = 25, cursor: Cursor = None) -> Page[Comment]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        task_access(conn, principal, task_id)
        rows = comments.list_comments(conn, task_id, limit + 1, after)
    return make_page(rows, limit, Comment, lambda row: [row["created_at"], row["id"]])


@router.post("/v1/tasks/{task_id}/comments", response_model=Comment, status_code=201)
def create_comment(task_id: UUID, body: CommentCreate, principal: Writer, db: Db, settings: AppSettings,
                   idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", f"/v1/tasks/{task_id}/comments", body)
    with db.transaction(principal.user_id) as conn:
        task_access(conn, principal, task_id)

        def create() -> dict:
            comment_id = comments.create_comment(conn, task_id, principal.user_id, body.body)
            return to_json(Comment, comments.get_comment(conn, comment_id))

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/comments", data["id"]), replayed=replayed)


@router.delete("/v1/comments/{comment_id}", status_code=204)
def delete_comment(comment_id: UUID, principal: Writer, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        owner, access = comment_access(conn, principal, comment_id)
        if not access.can_manage and owner["author_id"] != principal.user_id:
            raise forbidden("Only the author, a team lead or an admin may delete a comment.")
        comments.delete_comment(conn, comment_id)
    return Response(status_code=204)
