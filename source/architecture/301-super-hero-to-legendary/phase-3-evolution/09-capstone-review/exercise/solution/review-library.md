# Design review: Community Library architecture package

Reviewer: course example. Date: 2026-11-23. Documents reviewed: the Community Library files from level 201 lesson 10 (context, containers, components, ADR 0001, quality scenarios and risks).

## Scope and boundary
The review covers the documents only. The system is invented, so the facts in it are assumptions, not measurements.

## What works well
- The loan rule is owned by one place and one database step, which prevents a double loan, and an ADR records the cost.
- The e-mail service is drawn as external in every view.

## Findings
| Id | Lens | Finding | Evidence | Severity | Recommendation | Question for the authors |
|---|---|---|---|---|---|---|
| F1 | Failure and resilience | The Library API calls the e-mail service with no timeout, retry or fallback described, so a slow e-mail service could slow loans | containers.mmd and components.mmd | Medium | Send reminders through a queue and a separate worker, with a bounded number of tries | Do reminders run inside the loan request? |
| F2 | Security | Scenario Q2 protects member history, but no diagram shows how a member is identified or where the check lives | quality.md scenario Q2 and components.mmd | Medium | Add an identity provider to the context and a token or session check component | How do members sign in? |
| F3 | Observability and SLOs | There is no measure of whether loans succeed, only scenarios | quality.md | Low | Define an SLI such as the share of loan requests that succeed, with an owner | Who watches it? |

## Verdict
Accept with conditions: close F1 and F2 before building; define the SLI in F3 when the first version runs.
