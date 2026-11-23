# ADR 0003: Keep atomic business rules in database functions

Status: Accepted (recorded after the fact from the platform TDD, section 4)
Date: 2026-11-23
Owner: Platform maintainers

## Context
Four backends in four languages must complete a task, reassign a task and create a team in exactly the same way, even when two requests arrive at once.

## Options
- Write each rule in every backend. Cost: four implementations that can drift apart.
- Put each rule in one database function that locks the rows and checks the version. Cost: harder to unit test, and every change needs a migration.

## Decision
Keep the atomic rules in database functions and let the backends call them.

## Consequences
- Benefit: the rule exists once, and a concurrent change cannot interleave with it.
- Cost or risk: the rule is tested through the database, and a change to it is a migration, not only a code change.

## Revisit when
A rule changes more often than migrations can be reviewed, or a backend needs a rule the functions cannot express. Reviewer: the platform maintainers.
