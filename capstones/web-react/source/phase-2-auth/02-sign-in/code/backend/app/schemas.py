from datetime import date, datetime
from typing import Annotated, Any, ClassVar, Generic, Literal, TypeVar
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, field_validator, model_validator
from pydantic.alias_generators import to_camel

Role = Literal["admin", "member"]
TeamRole = Literal["lead", "member"]
TaskStatus = Literal["todo", "in_progress", "blocked", "done", "cancelled"]
TaskPriority = Literal["low", "medium", "high", "urgent"]
AuditEntityType = Literal["team", "member", "project", "task", "comment"]

TeamName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=80)]
ProjectKey = Annotated[str, StringConstraints(pattern=r"^[A-Z][A-Z0-9]{1,9}$")]
ProjectName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=120)]
TaskTitle = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)]
CommentBody = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=2000)]
TeamDescription = Annotated[str, Field(max_length=500)]
ProjectDescription = Annotated[str, Field(max_length=2000)]
TaskDescription = Annotated[str, Field(max_length=10000)]

T = TypeVar("T")


class ApiModel(BaseModel):
    """Response DTOs: Python names are snake_case, JSON names are camelCase."""

    model_config = ConfigDict(alias_generator=to_camel, validate_by_name=True, validate_by_alias=True, from_attributes=True)


class RequestModel(BaseModel):
    """Request DTOs accept only the camelCase names and reject unknown members (additionalProperties: false)."""

    model_config = ConfigDict(alias_generator=to_camel, extra="forbid")


class PatchModel(RequestModel):
    """JSON Merge Patch (RFC 7396): send only what changes; null clears a field only where the contract allows it."""

    nullable: ClassVar[frozenset[str]] = frozenset()

    @field_validator("*", mode="before")
    @classmethod
    def reject_null(cls, value: Any, info: Any) -> Any:
        if value is None and info.field_name not in cls.nullable:
            raise ValueError("null is not allowed for this field")
        return value

    @model_validator(mode="after")
    def require_one_field(self) -> "PatchModel":
        if not self.model_fields_set:
            raise ValueError("at least one field is required")
        return self


# Requests -------------------------------------------------------------------

class TeamCreate(RequestModel):
    name: TeamName
    description: TeamDescription = ""
    lead_user_id: UUID | None = None


class TeamUpdate(PatchModel):
    name: TeamName | None = None
    description: TeamDescription | None = None


class MemberPut(RequestModel):
    role: TeamRole


class ProjectCreate(RequestModel):
    key: ProjectKey
    name: ProjectName
    description: ProjectDescription = ""


class ProjectUpdate(PatchModel):
    name: ProjectName | None = None
    description: ProjectDescription | None = None
    archived: bool | None = None


class TaskCreate(RequestModel):
    title: TaskTitle
    description: TaskDescription = ""
    priority: TaskPriority = "medium"
    assignee_id: UUID | None = None
    due_date: date | None = None


class TaskUpdate(PatchModel):
    nullable: ClassVar[frozenset[str]] = frozenset({"assignee_id", "due_date"})

    title: TaskTitle | None = None
    description: TaskDescription | None = None
    status: TaskStatus | None = None
    priority: TaskPriority | None = None
    assignee_id: UUID | None = None
    due_date: date | None = None


class ReassignRequest(RequestModel):
    assignee_id: UUID | None


class CommentCreate(RequestModel):
    body: CommentBody


# Responses ------------------------------------------------------------------

class Health(ApiModel):
    status: Literal["ok", "degraded"]
    version: str | None = None
    database: Literal["up", "down"] | None = None


class PageInfo(ApiModel):
    limit: int
    next_cursor: str | None


class Page(ApiModel, Generic[T]):
    items: list[T]
    page: PageInfo


class UserSummary(ApiModel):
    id: UUID
    username: str
    display_name: str


class TeamRef(ApiModel):
    team_id: UUID
    name: str
    role: TeamRole


class Me(ApiModel):
    id: UUID
    username: str
    email: str
    display_name: str
    roles: list[Role]
    scopes: list[str]
    teams: list[TeamRef]


class Team(ApiModel):
    id: UUID
    name: str
    description: str
    member_count: int
    created_by: UUID
    version: int
    created_at: datetime
    updated_at: datetime


class Member(ApiModel):
    user_id: UUID
    username: str
    display_name: str
    role: TeamRole
    joined_at: datetime


class Project(ApiModel):
    id: UUID
    team_id: UUID
    key: str
    name: str
    description: str
    archived: bool
    version: int
    created_at: datetime
    updated_at: datetime


class Task(ApiModel):
    id: UUID
    project_id: UUID
    title: str
    description: str
    status: TaskStatus
    priority: TaskPriority
    assignee_id: UUID | None
    due_date: date | None
    completed_at: datetime | None
    created_by: UUID
    version: int
    created_at: datetime
    updated_at: datetime


class Comment(ApiModel):
    id: UUID
    task_id: UUID
    author: UserSummary
    body: str
    created_at: datetime


class AuditEntry(ApiModel):
    id: int
    occurred_at: datetime
    actor_id: UUID | None
    action: Literal["create", "update", "delete"]
    entity_type: AuditEntityType
    entity_id: UUID
    details: dict[str, Any]
