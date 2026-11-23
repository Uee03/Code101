# Error budget policy

The policy is agreed in advance by the product owner and the engineering team, so nobody argues about it during an incident.

| Budget state | Meaning | What the team does |
|---|---|---|
| Healthy | Much of the budget remains | Ship features and take planned risks, such as experiments and drills |
| Low | The remaining budget is below a level the team agreed | Review the largest causes of bad events; prefer reliability work before new risky changes |
| Spent | The budget for the window is used up | Pause risky changes; only fixes, reliability work and security changes ship until the budget recovers |

Rules:
- An incident that spends a large part of the budget gets a written review with actions and owners.
- If the budget is never used, the target may be too lax or the system over-protected; revisit the target.
- If the budget is always spent, the target is unrealistic or the system needs reliability investment; the owner decides which.
- Alerts follow symptoms users feel, such as a fast burn of the budget, and not every internal cause.
