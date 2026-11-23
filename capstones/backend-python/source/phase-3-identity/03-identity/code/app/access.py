from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import Connection

from app.auth import Principal
from app.errors import ProblemError, forbidden, not_found
from app.repositories import comments, projects, tasks, teams
from app.repositories.sql import Row


@dataclass(frozen=True)
class Access:
    """What the caller may do inside one team: 'admin' (everything), 'lead' (manage) or 'member' (work)."""

    team_id: UUID
    level: str

    @property
    def can_manage(self) -> bool:
        return self.level in ("admin", "lead")

    def require_manage(self, action: str) -> None:
        if not self.can_manage:
            raise forbidden(f"Only a team lead or an admin may {action}.")


def team_access(conn: Connection, principal: Principal, team_id: UUID) -> Access:
    """404 for a team that does not exist AND for a team the caller does not belong to, so ids cannot be probed."""
    row = teams.get_access(conn, team_id, principal.user_id)
    if row is None or (row["role"] is None and not principal.is_admin):
        raise not_found("The team was not found.")
    return Access(team_id, "admin" if principal.is_admin else row["role"])


def project_access(conn: Connection, principal: Principal, project_id: UUID) -> tuple[Row, Access]:
    project = projects.get_project(conn, project_id)
    if project is None:
        raise not_found("The project was not found.")
    try:
        return project, team_access(conn, principal, project["team_id"])
    except ProblemError:
        raise not_found("The project was not found.") from None


def task_access(conn: Connection, principal: Principal, task_id: UUID) -> tuple[Row, Access]:
    task = tasks.get_task(conn, task_id)
    if task is None:
        raise not_found("The task was not found.")
    try:
        return task, team_access(conn, principal, task["team_id"])
    except ProblemError:
        raise not_found("The task was not found.") from None


def comment_access(conn: Connection, principal: Principal, comment_id: UUID) -> tuple[Row, Access]:
    owner = comments.get_owner(conn, comment_id)
    if owner is None:
        raise not_found("The comment was not found.")
    try:
        return owner, team_access(conn, principal, owner["team_id"])
    except ProblemError:
        raise not_found("The comment was not found.") from None
