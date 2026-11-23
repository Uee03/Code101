# Design review: P07 event-driven order processing

Reviewer: course example. Date: 2026-11-23. Documents reviewed: capstones/_practice/P07-event-driven-order-processing/TDD.md sections 1 to 6. Everything below comes from those sections. P07 is a practice brief that learners build, so some findings are questions the learner must answer in their own ADRs.

## Scope and boundary
The review covers the stated requirements, the suggested architecture and the list of decisions. It does not review any learner's implementation.

## What works well
- The brief says what it will not claim: no exactly-once delivery, and design for at-least-once delivery with idempotency.
- Every order must end in a final state, and a consistency checker proves it after each drill.
- Timeouts, retries with backoff and jitter, and a circuit breaker are required on every outbound call, and chaos drills are required to prove them.
- Metric labels with unbounded values are listed as a decision to make, which protects the metrics system.
- No card data exists anywhere in the system.

## Findings
| Id | Lens | Finding | Evidence | Severity | Recommendation | Question for the authors |
|---|---|---|---|---|---|---|
| P1 | Events and sagas | The read model must be rebuildable by replaying events, but the broker choice is left open; queues that discard acknowledged messages cannot replay | Requirement R-11 and decision 2 | Medium | Make replay an explicit criterion in the broker ADR and keep an event history that supports it | Where does the history live and how long is it kept? |
| P2 | Events and sagas | The requirements do not say what happens when a compensation such as a refund keeps failing | R-08, R-09 and the failure matrix | Medium | Require retried, idempotent compensations, a bounded number of tries, a dead-letter path and an alert for a stuck order | Which state is an order in while a compensation is failing? |
| P3 | Failure and resilience | The scope is Docker Compose only, so the broker is presumably a single instance; the drills cover a restart but not loss of its storage | R-21, non-goals and R-22 | Low for a learning stack | State the accepted limit in an ADR | Is loss of broker storage an expected drill? |
| P4 | Security | Service-to-service identity is required, but access rules on the broker itself, who may publish or consume which event types, are not mentioned | R-20 and decision 9 | Medium | Give each service its own broker identity with the smallest rights, and consider a check of the producer field in consumers | How are broker identities created and rotated? |
| P5 | Observability and SLOs | Many metrics are required but no service level objective ties them to a user journey | R-12, R-15 and N-02 | Medium | Define an SLI and an SLO for orders reaching a final state, with an error budget policy | Which latency target becomes the SLO and who agrees it? |
| P6 | Evolution | The split into services is the learning goal; the brief itself describes problems, a slow courier call and a non-atomic stock reservation, that a modular monolith might also fix | Section 1, the brief | Low | Add a short ADR that records why services are chosen and what evidence would have justified staying modular | What measurement would have justified the split? |
| P7 | Cost and capacity | Throughput and memory targets are given for one laptop, but there is no model that links them, for example orders in flight at the target rate | N-01, N-02 and N-05 | Low | Add the in-flight estimate and the broker event rate to the capacity notes | Which resource saturates first? |

## Trade-off and sensitivity points
- Choreography keeps services independent and makes the flow harder to see; an order state owner and good traces reduce that cost.
- Retry counts and breaker thresholds are sensitivity points: small changes decide whether an outage stays small or turns into a retry storm.
- Prefetch and in-flight limits trade throughput for stable memory.

## Quality scenario check
- No double stock reservation, one charge per order and a final state for every order: each has a measurable acceptance criterion and a drill or checker.
- Slow courier: required to leave Orders unaffected, with a ten-second latency drill.
- Rebuild of the read model: a criterion exists, and P1 shows what it needs from the broker choice.

## Verdict
Accept with conditions as a practice brief: close P1, P2 and P4 in the learner's ADRs, define the SLO in P5, and record P6 so the choice of services is a decision and not a reflex.
