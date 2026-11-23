# Design review: Tasks and Teams platform

Reviewer: course example. Date: 2026-11-23. Documents reviewed: capstones/platform/README.md and capstones/platform/TDD.md sections 2 to 7. Everything below comes from those sections; where they are silent the review asks a question instead of assuming.

## Scope and boundary
The review covers the platform contract and its local stack: the API contract, the database, the identity realm and the conformance checks. Production hosting is out of scope in the TDD, so findings about it are conditional on a later production use.

## What works well
- Atomic rules in database functions with row locking and a version check give strong consistency where lost updates would hurt.
- Object-level authorisation by team membership, with 404 for objects the caller cannot see, together with a limited database role and an audit trigger, gives defence in depth.
- Strong ETags with If-Match and idempotency keys protect clients from lost updates and duplicate creates.
- Contract first with a black-box conformance script makes the four backends interchangeable and testable.

## Findings
| Id | Lens | Finding | Evidence | Severity | Recommendation | Question for the authors |
|---|---|---|---|---|---|---|
| F1 | Scale | The place where rate-limit counters are kept is not stated, so with several backend instances the limit could be applied per instance | TDD section 6, rate limits | Medium | Choose a shared counter store and record fail-open or fail-closed behaviour in an ADR | Where do the counters live, and what happens if that store is unreachable? |
| F2 | Failure and resilience | The TDD describes one PostgreSQL database and no backup, restore or recovery objective | TDD sections 2 and 5 | Medium for any production use | Write a runbook with a tested restore and agree a recovery objective | Is a recovery objective expected before production use? |
| F3 | Observability and SLOs | The sections reviewed define a trace id in error responses but no metrics, service level objectives or alerts | TDD section 6, problem details | Medium | Define SLIs for the main journeys and an error budget policy | Where will the golden signals be measured? |
| F4 | Security | A revoked or leaked token stays valid until it expires, five minutes in the realm settings | TDD section 4 decisions and section 3 token lifetime | Low, accepted trade-off | Keep the trigger in the risk register and protect any operation that needs instant revocation with an extra check | Which operations, if any, need instant revocation? |
| F5 | Evolution | The conformance script runs 14 API checks while the contract has 27 operations, so some operations rely on the backend's own tests | README, status and the conformance row | Low | Track which operations are unchecked and add checks over time | How is drift in an unchecked operation detected? |
| F6 | Scale | A read replica is not described; if one is added later, reads that precede an If-Match update need a rule | TDD sections 4 and 6 | Low | Record the read-after-write rule in an ADR before adding a replica | Is a replica planned? |
| F7 | Security | The realm file is imported once, so later console changes could drift from the file in the repository | TDD section 4, Keycloak realm file decision | Low | Export and review realm changes, as the TDD already suggests for real systems | Who owns realm changes? |

## Trade-off and sensitivity points
- The five-minute access token life trades outage tolerance and fewer network calls against a longer window for a leaked token.
- Rules in database functions trade one shared implementation against harder unit testing and migrations for every change.

## Quality scenario check
- Concurrent edit, repeated create and probing another team's task: the design shows how each is met and the conformance script or backend tests can check them.
- Short identity outage: met by cached keys, but only as long as tokens are valid; no test is described.
- Listing speed: a target exists for local seed data only, which cannot predict production behaviour.

## Verdict
Accept with conditions for use as a teaching contract and local stack. Before any production use: close F1 and F2, define SLIs for F3, and record decisions F6 and F7 as ADRs.
