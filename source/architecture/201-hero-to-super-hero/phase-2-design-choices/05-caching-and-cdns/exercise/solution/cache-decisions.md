# Cache decisions to complete

| Data | Who may keep a copy | Where | Freshness rule | What makes it stale | Risk if stale or shared |
|---|---|---|---|---|---|
| The current user's profile from GET /v1/me | Only that user | Browser, private | Short lifetime chosen from measurements, or revalidate | A role or team change | A user keeps seeing old roles and teams |
| The list of projects of one team | Only members of that team | Application cache keyed by team id and user id | Short lifetime chosen from measurements; remove on a project change | A project is created, renamed or archived | A new project is missing for a while |
| The health endpoint GET /health | Nobody | Not cached | Always current | Not applicable | A monitor reads an old state and misses an outage |
