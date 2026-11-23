# Tasks and Teams: project-board documentation review

Audience: a new team member and a maintainer.
Question: how does an allowed member read a task?
Scope: web client, one backend, work database and external identity.
Omitted: mobile clients, comments, audit records and full field lists.
Evidence: capstones/platform/README.md and capstones/platform/TDD.md.
Identity is external to this work-planning boundary even if locally operated.
HTTPS labels describe intended production communication, not local setup.

## Files
- context.mmd: people and neighbouring systems.
- containers.mmd: applications, data store and responsibilities.
- sequence.mmd: one already-signed-in member reads an allowed task.
- data.mmd: the teams, projects and tasks subset of stored relationships.
- 001-postgres.md: why work records use PostgreSQL.
- 002-keycloak.md: why sign-in is delegated.

## Review checklist
- [ ] Title, audience, question, scope and omissions are explicit.
- [ ] Context has no database or internal client boxes.
- [ ] Container boundary matches the context boundary.
- [ ] Every relationship has a direction and a readable meaning.
- [ ] Sequence participants exist in the container view.
- [ ] Token validation and team access happen before the task is returned.
- [ ] Stored record names agree with the sequence and the platform.
- [ ] Each task belongs to one project; each project belongs to one team.
- [ ] Both ADRs contain options, reasons, a cost, an owner and a review trigger.
- [ ] No secrets, real personal data or colour-only meanings appear.
- [ ] A second reader can describe the request journey without guessing.
- [ ] Diagram sources remain editable and the Markdown listings match them.

## Known limits
These are documentation sources, not a running system or proof of its security.
The simplified state and entity views elsewhere are not the complete platform contract.
