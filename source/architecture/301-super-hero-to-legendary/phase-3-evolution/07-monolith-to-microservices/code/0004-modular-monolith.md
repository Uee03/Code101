# ADR 0004: Stay a modular monolith and extract only on evidence

Status: Proposed
Date: 2026-11-23
Owner: Platform maintainers

## Context
Each platform backend is one deployable program with an HTTP layer, an application layer and a data layer, sharing one database. Business rules that must be atomic live in database functions. No measurement shows a part that needs different scaling, a release conflict between teams or a failure that spreads between parts.

## Options
- Keep one deployable and make its modules explicit, each with a public interface and its own tables. Cost: module boundaries must be enforced by review and checks, because the compiler does not enforce them everywhere.
- Split into services now (teams, work, comments, audit). Cost: network calls, distributed transactions and operations for each service, with no measured gain.
- Extract one module later, behind a facade, when evidence appears. Cost: the migration work is paid when needed.

## Decision
Keep the modular monolith. Extract a module, starting with the one that has the clearest data ownership, only when a row of the decision framework shows measured evidence.

## Consequences
- Benefit: atomic rules stay simple, operations stay small, and a later extraction remains possible.
- Cost or risk: modules may erode into a tangle unless their boundaries are checked in review.

## Revisit when
Measurements show one module needs independent scaling, or two teams cannot release independently. Reviewer: the platform maintainers.
