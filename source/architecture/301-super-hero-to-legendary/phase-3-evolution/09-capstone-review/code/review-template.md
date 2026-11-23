# Design review: <system name>

Reviewer: <name>. Date: <date>. Documents reviewed: <list with section numbers>.

## Scope and boundary
What this review covers, what it does not cover, and which assumptions about the system boundary it makes.

## What works well
Decisions that are sound for the stated scenarios, and why (non-risks).

## Findings
| Id | Lens | Finding | Evidence (document and section) | Severity | Recommendation | Question for the authors |
|---|---|---|---|---|---|---|
| F1 | <lens> | <what you found> | <where you saw it> | <high, medium or low> | <what to do> | <what you could not tell from the documents> |

Lenses: scale, consistency, events and sagas, failure and resilience, observability and SLOs, security, evolution, cost and capacity.

Severity:
- High: could cause data loss, a security breach or a long outage, with no mitigation in the design.
- Medium: a likely problem, or a gap in the design that the authors should close before building.
- Low: an improvement, a clarification or a missing record of a decision.

## Trade-off and sensitivity points
Decisions that improve one quality and worsen another, and settings where a small change has a large effect.

## Quality scenario check
For each important quality scenario: does the design show how it is met, and is there a way to test it?

## Verdict
One of: accept, accept with conditions (list them), or rework (say what must change). Then the next steps, with owners.
