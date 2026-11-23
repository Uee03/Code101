from datetime import date
from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Header, Query, Response
from sqlalchemy import Connection

from app.access import project_access, task_access
from app.auth import Reader, Writer
from app.dependencies import AppSettings, Db
from app.errors import ProblemError
from app.http import (IdempotencyKey, IfMatch, created, etag_matches, json_with_etag, make_etag, parse_if_match,
                      resource_url, to_json)
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, as_optional_date, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import members, tasks
from app.repositories.sql import lock_and_check
from app.schemas import Page, ReassignRequest, Task, TaskCreate, TaskPriority, TaskStatus, TaskUpdate

router = APIRouter(tags=["Tasks"])
TaskSort = Annotated[Literal["-createdAt", "createdAt", "dueDate"], Query()]


def require_team_member(conn: Connection, team_id: UUID, assignee_id: UUID | None) -> None:
    """An assignee must belong to the project's team. This is a field problem, so it is a 422 with a pointer."""
    if assignee_id is not None and members.get_membership(conn, team_id, assignee_id) is None:
        raise ProblemError(422, "One or more fields are invalid.",
                           errors=[{"pointer": "/assigneeId", "detail": "must be a member of the project's team"}])


@router.get("/v1/projects/{project_id}/tasks", response_model=Page[Task])
def list_tasks(
    project_id: UUID, principal: Reader, db: Db,
    status: Annotated[list[TaskStatus] | None, Query(description="Repeat to match several statuses.")] = None,
    priority: Annotated[list[TaskPriority] | None, Query()] = None,
    assignee_id: Annotated[UUID | None, Query(alias="assigneeId")] = None,
    due_before: Annotated[date | None, Query(alias="dueBefore")] = None,
    due_after: Annotated[date | None, Query(alias="dueAfter")] = None,
    q: Annotated[str | None, Query(min_length=1, max_length=100)] = None,
    sort: TaskSort = "-createdAt", limit: Limit = 25, cursor: Cursor = None,
) -> Page[Task]:
    parsers = [as_optional_date, as_uuid] if sort == "dueDate" else [as_timestamp, as_uuid]
    after = decode_cursor(cursor, parsers) if cursor else None
    with db.transaction() as conn:
        project_access(conn, principal, project_id)
        rows = tasks.list_tasks(conn, project_id, statuses=status or [], priorities=priority or [], assignee_id=assignee_id,
                                due_before=due_before, due_after=due_after, title_contains=q, sort=sort,
                                limit=limit + 1, after=after)
    key = "due_date" if sort == "dueDate" else "created_at"
    return make_page(rows, limit, Task, lambda row: [row[key], row["id"]])


@router.post("/v1/projects/{project_id}/tasks", response_model=Task, status_code=201)
def create_task(project_id: UUID, body: TaskCreate, principal: Writer, db: Db, settings: AppSettings,
                idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", f"/v1/projects/{project_id}/tasks", body)
    with db.transaction(principal.user_id) as conn:
        _, access = project_access(conn, principal, project_id)
        require_team_member(conn, access.team_id, body.assignee_id)

        def create() -> dict:
            row = tasks.create_task(conn, project_id, body.title, body.description, body.priority,
                                    body.assignee_id, body.due_date, principal.user_id)
            return to_json(Task, row)

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/tasks", data["id"]), replayed=replayed)


@router.get("/v1/tasks/{task_id}", response_model=Task)
def get_task(task_id: UUID, principal: Reader, db: Db, if_none_match: Annotated[str | None, Header()] = None):
    with db.transaction() as conn:
        task, _ = task_access(conn, principal, task_id)
    etag = make_etag(task["version"])
    if etag_matches(if_none_match, task["version"]):
        return Response(status_code=304, headers={"ETag": etag})
    return json_with_etag(Task, task)


@router.patch("/v1/tasks/{task_id}", response_model=Task)
def update_task(task_id: UUID, body: TaskUpdate, principal: Writer, db: Db, if_match: IfMatch = None):
    expected_version = parse_if_match(if_match)
    changes = body.model_dump(exclude_unset=True)
    with db.transaction(principal.user_id) as conn:
        _, access = task_access(conn, principal, task_id)
        require_team_member(conn, access.team_id, changes.get("assignee_id"))
        lock_and_check(conn, "tasks", task_id, expected_version, "task")
        tasks.update_task(conn, task_id, changes)
        task = tasks.get_task(conn, task_id)
    return json_with_etag(Task, task)


@router.delete("/v1/tasks/{task_id}", status_code=204)
def delete_task(task_id: UUID, principal: Writer, db: Db, if_match: IfMatch = None) -> Response:
    expected_version = parse_if_match(if_match, required=False)
    with db.transaction(principal.user_id) as conn:
        _, access = task_access(conn, principal, task_id)
        access.require_manage("delete tasks")
        lock_and_check(conn, "tasks", task_id, expected_version, "task")
        tasks.delete_task(conn, task_id)
    return Response(status_code=204)


@router.post("/v1/tasks/{task_id}/complete", response_model=Task)
def complete_task(task_id: UUID, principal: Writer, db: Db, if_match: IfMatch = None):
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        task_access(conn, principal, task_id)
        tasks.complete_task(conn, task_id, principal.user_id, expected_version)
        task = tasks.get_task(conn, task_id)
    return json_with_etag(Task, task)


@router.post("/v1/tasks/{task_id}/reassign", response_model=Task)
def reassign_task(task_id: UUID, body: ReassignRequest, principal: Writer, db: Db, if_match: IfMatch = None):
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        _, access = task_access(conn, principal, task_id)
        access.require_manage("reassign tasks")
        tasks.reassign_task(conn, task_id, body.assignee_id, principal.user_id, expected_version)
        task = tasks.get_task(conn, task_id)
    return json_with_etag(Task, task)
