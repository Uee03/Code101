# Choose per operation

| Operation | Strong or eventual | If the deciding node is unreachable | Reason |
|---|---|---|---|
| Add a user to a team (a lead does this) | Strong | Refuse the change | The membership check for later requests depends on it, and a stale answer would grant or hide access |
| Refuse to remove the last lead of a team | Strong | Refuse the change | The rule compares the current set of leads; deciding from old data could leave a team with no lead |
| Show how many tasks were completed this week on a dashboard | Eventual | Show the last value with its age | A figure that is briefly old harms nobody |
| Charge a payment once for an order (P07 Payments) | Strong for the charge record, plus an idempotency key | Refuse or retry later, never charge blindly | A second charge cannot be undone silently |
