from uuid import UUID

from fastapi import APIRouter, Response

from app.access import project_access, team_access
from app.auth import Reader, Writer
from app.dependencies import AppSettings, Db
from app.http import IdempotencyKey, IfMatch, created, make_etag, parse_if_match, resource_url, to_json
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, SortCreated, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import projects
from app.repositories.sql import lock_and_check
from app.schemas import Page, Project, ProjectCreate, ProjectUpdate

router = APIRouter(tags=["Projects"])


@router.get("/v1/teams/{team_id}/projects", response_model=Page[Project])
def list_projects(team_id: UUID, principal: Reader, db: Db, archived: bool = False, sort: SortCreated = "-createdAt",
                  limit: Limit = 25, cursor: Cursor = None) -> Page[Project]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        team_access(conn, principal, team_id)
        rows = projects.list_projects(conn, team_id, archived, sort == "-createdAt", limit + 1, after)
    return make_page(rows, limit, Project, lambda row: [row["created_at"], row["id"]])


@router.post("/v1/teams/{team_id}/projects", response_model=Project, status_code=201)
def create_project(team_id: UUID, body: ProjectCreate, principal: Writer, db: Db, settings: AppSettings,
                   idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", f"/v1/teams/{team_id}/projects", body)
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("create projects")

        def create() -> dict:
            return to_json(Project, projects.create_project(conn, team_id, body.key, body.name, body.description, principal.user_id))

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/projects", data["id"]), replayed=replayed)


@router.get("/v1/projects/{project_id}", response_model=Project)
def get_project(project_id: UUID, response: Response, principal: Reader, db: Db) -> Project:
    with db.transaction() as conn:
        project, _ = project_access(conn, principal, project_id)
    response.headers["ETag"] = make_etag(project["version"])
    return Project.model_validate(project)


@router.patch("/v1/projects/{project_id}", response_model=Project)
def update_project(project_id: UUID, body: ProjectUpdate, response: Response, principal: Writer, db: Db,
                   if_match: IfMatch = None) -> Project:
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        _, access = project_access(conn, principal, project_id)
        access.require_manage("change the project")
        lock_and_check(conn, "projects", project_id, expected_version, "project")
        projects.update_project(conn, project_id, body.model_dump(exclude_unset=True))
        project = projects.get_project(conn, project_id)
    response.headers["ETag"] = make_etag(project["version"])
    return Project.model_validate(project)


@router.delete("/v1/projects/{project_id}", status_code=204)
def delete_project(project_id: UUID, principal: Writer, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        _, access = project_access(conn, principal, project_id)
        access.require_manage("delete the project")
        projects.delete_project(conn, project_id)
    return Response(status_code=204)
