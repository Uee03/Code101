# Quality scenarios and risks: Community Library

## Q1 Integrity: no double loan
- Source: two librarians at different branches.
- Stimulus: both lend the same copy at nearly the same moment.
- Environment: normal operation.
- Artifact: the loan rule in the Library API and database.
- Response: one loan is recorded and the other is refused with a clear message.
- Response measure: the copy has exactly one active loan afterwards.
- Basis: proposal, measure first.

## Q2 Privacy: member data
- Source: a member.
- Stimulus: asks for another member's loan history.
- Environment: normal operation.
- Artifact: the access checks of the Library API.
- Response: the request is refused without revealing that the history exists.
- Response measure: every such request returns the same not-found answer.
- Basis: proposal, measure first.

## Risks
| Id | Risk | Scenario | Likelihood | Impact | Mitigation | Trigger to act | Owner |
|---|---|---|---|---|---|---|---|
| R1 | Lending stops when the API or database is down | Q1 | Low | High | Backups and a recovery plan; staff write loans on paper during short outages | Outages reported by branches | Library system team |
| R2 | Reminder e-mails fail silently | Q2 | Medium | Low | Show overdue loans on the staff screen as well | Members report missing reminders | Library system team |
