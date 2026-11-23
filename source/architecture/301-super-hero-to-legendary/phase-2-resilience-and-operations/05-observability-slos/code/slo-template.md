# SLO template and example

An SLI (service level indicator) is a measured ratio of good events to valid events. An SLO (service level objective) is the target for that ratio over a window. The error budget is the share of events allowed to be bad.

## Template
| Field | Content |
|---|---|
| Service and user journey | What the user is trying to do |
| SLI | Good events divided by valid events, with both defined exactly |
| Where it is measured | The place in the system where the events are counted |
| Window | The period the target applies to, for example a rolling period |
| SLO target | The target ratio, agreed with the product owner |
| Exclusions | Events that do not count, and why |
| Error budget | One minus the target, as a share of valid events |
| Owner and review date | Who is accountable and when the target is reviewed |

## Example: platform API availability (the target is a placeholder)
| Field | Content |
|---|---|
| Service and user journey | A signed-in user reads and changes tasks through the API |
| SLI | Requests under /v1 that do not end in a 5xx status, divided by all requests under /v1 that reach the API |
| Where it is measured | At the API, from its own request metrics |
| Window | A rolling window chosen with the product owner |
| SLO target | To be agreed after measuring a baseline. The TDD gives no availability target |
| Exclusions | Requests answered 429 because a client exceeded its rate limit, and planned maintenance announced in advance |
| Error budget | One minus the target |
| Owner and review date | Platform maintainers, reviewed after each incident |

## Arithmetic for time-based and request-based budgets
This is illustrative arithmetic, not a target. For a time-based view, a window of 30 days has 30 x 24 x 60 = 43,200 minutes. A target of 99.9 percent leaves 0.1 percent of that, which is 43.2 minutes of allowed bad time. For a request-based view, the budget is the number of valid requests multiplied by one minus the target.
