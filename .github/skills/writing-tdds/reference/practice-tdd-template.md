# TDD template: practice capstone (no source code)

The learner builds this alone, in a **1 to 3 month sprint**, broken into weekly phases. The TDD is the whole brief. No solution code ships.

````markdown
# Practice capstone: <Name>

| Field | Value |
|-------|-------|
| Id | P<NN>-<slug> |
| Level | 201 or 301 |
| Sprint length | <4 / 6 / 8 / 12 weeks> (about <h> hours per week) |
| Prerequisites | <101/201 tracks and lessons> |
| Suggested stacks | <2 to 3 options, e.g. Python+FastAPI+React, ASP.NET+Angular, Go+Flutter> |
| Last updated | <date> |

## 1. The brief
Client story in plain language (a fictional client, their problem, who uses it). What the learner will have at the end (demoable).

## 2. Goals and non-goals
Learning goals (skills) and explicit non-goals.

## 3. Users and scenarios
Personas and 5 to 8 user stories in "As a ..., I want ..., so that ..." form.

## 4. Requirements
| Id | Requirement | Priority (MoSCoW) | Acceptance criteria (testable, Given/When/Then or measurable) |
Non-functional requirements with numbers.

## 5. Suggested architecture
Context diagram (Mermaid) and component list. Hints, not answers: name the decisions the learner must make and the trade-offs.

## 6. Data model starting point
Entities and key relationships (names only or ER sketch). The learner designs columns, constraints and indexes.

## 7. API or interface sketch
Resources and key operations (table). The learner writes the contract.

## 8. Security and identity
What must be protected, roles, and which standards apply (OIDC, OWASP). The learner designs the flows.

## 9. Sprint plan
| Week | Phase | Deliverables | Exit criteria (how the learner knows it is done) |
Each phase is demoable. First phase is a walking skeleton.

## 10. Verification
How the learner proves it works: smoke checklist, demo script, what to measure. Docker is temporary and cleaned up.

## 11. Grading rubric
| Criterion | Weight | Beginner (1) | Solid (3) | Excellent (5) |
(correctness, design, security, tests, docs, operations, polish)

## 12. Stretch goals
5 to 8 optional challenges ranked by difficulty.

## 13. Hints and pitfalls
Common traps, where to look in Code101 lessons (link lesson ids), Tier 1 references.

## 14. Deliverables checklist
README, diagrams, TDD update (the learner's own as-built notes), demo.
````
