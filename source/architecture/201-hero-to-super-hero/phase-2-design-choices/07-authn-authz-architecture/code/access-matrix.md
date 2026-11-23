# Access matrix: selected Tasks and Teams operations

Source: platform TDD section 6. Effective permission is the intersection of scope and role, then the team check.

| Operation | Access value | Scope needed | Object-level check |
|---|---|---|---|
| GET /health | public | none | none |
| GET /v1/me | any signed-in user | tasks:read | none, the caller is the subject |
| POST /v1/teams | admin | tasks:write | none |
| DELETE /v1/teams/{teamId} | admin | tasks:admin | none |
| PATCH /v1/teams/{teamId} | team lead or admin | tasks:write | caller leads this team |
| POST /v1/projects/{projectId}/tasks | member or admin | tasks:write | caller belongs to the project's team |
| DELETE /v1/comments/{commentId} | author, team lead or admin | tasks:write | caller wrote it or leads the team |
| GET /v1/audit-log | admin | tasks:admin | none |
