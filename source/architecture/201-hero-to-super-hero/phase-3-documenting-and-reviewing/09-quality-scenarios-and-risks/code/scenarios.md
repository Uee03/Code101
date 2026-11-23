# Quality scenarios: Tasks and Teams platform

Each scenario has the same six parts. "Basis" says where the target comes from. A basis of "proposal" means the number or behaviour has to be agreed and measured first.

## Q1 Performance: listing tasks
- Source: a signed-in team member.
- Stimulus: asks for one page of tasks of a project.
- Environment: normal operation, seed data, local machine.
- Artifact: the backend API and the database.
- Response: the page is returned.
- Response measure: p95 under 200 ms over 25 local requests.
- Basis: platform TDD, non-functional requirements.

## Q2 Security: probing another team's task
- Source: a signed-in member of team A.
- Stimulus: requests a task id that belongs to team B.
- Environment: normal operation.
- Artifact: the backend API authorisation checks.
- Response: the API answers as if the task does not exist.
- Response measure: every such request returns 404 and no response reveals that the task exists.
- Basis: platform TDD, visibility rule. A test for it is a proposal.

## Q3 Modifiability: adding a backend
- Source: a developer.
- Stimulus: implements the contract in a new language.
- Environment: development, with the shared database and identity service.
- Artifact: the new backend.
- Response: the backend is checked against the contract by a black-box script.
- Response measure: the script reports 18 passed and 0 failed before the backend may claim the contract.
- Basis: platform README and TDD.

## Q4 Reliability: short identity outage
- Source: the identity service stops answering.
- Stimulus: clients keep sending requests with unexpired access tokens.
- Environment: normal operation, signing keys already cached by the backend.
- Artifact: the backend token validation.
- Response: requests with valid tokens are still served; new sign-ins fail.
- Response measure: service continues until the access tokens expire, 5 minutes in the realm settings.
- Basis: platform TDD, token lifetime, and ADR 0002.

## Q5 Data integrity: concurrent edit
- Source: two members.
- Stimulus: both send a change to the same task using the same version in If-Match.
- Environment: normal operation.
- Artifact: the task update rule.
- Response: the first change is applied; the second is refused.
- Response measure: the second request returns 412 and no change is lost.
- Basis: platform TDD, concurrency rules.

## Q6 Data integrity: repeated create
- Source: a client that timed out.
- Stimulus: sends the same create request again with the same Idempotency-Key.
- Environment: within the 24 hours the key is kept.
- Artifact: the create endpoint and the key store.
- Response: the first response is replayed.
- Response measure: exactly one task exists and the reply carries Idempotent-Replayed true.
- Basis: platform TDD, idempotency rules.
