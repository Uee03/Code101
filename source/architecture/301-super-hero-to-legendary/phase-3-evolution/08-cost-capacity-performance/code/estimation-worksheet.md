# Estimation worksheet

Every input is marked measured, derived or assumed. An estimate built on assumed inputs is a hypothesis to test, not a result.

## Inputs
| Input | Symbol | Value | Source | Confidence |
|---|---|---|---|---|
| Registered users | U | to measure | Identity provider count | measured |
| Share of users active in the period | a | to measure | Sign-in logs | measured |
| Requests per active user per period | r | to measure | Request logs | measured |
| Seconds in the period | T | derived from the period | Calendar | derived |
| Peak factor, busiest second divided by the average second | k | to measure | Request logs at one-second resolution | measured |
| Mean time a request or order spends in the system | W | to measure | Latency metrics | measured |
| Records of one kind | N | to measure | Row counts | measured |
| Bytes per record, including indexes | b | to measure | Table size divided by row count | measured |
| Copies kept (replicas and backups) | c | design decision | Architecture | derived |
| Retention period | D | policy | Data policy | assumed until agreed |

## Formulas
- Average request rate: lambda = (U x a x r) / T
- Peak request rate: lambda_peak = lambda x k
- Requests in flight (Little's law): L = lambda x W
- Storage: S = N x b x c
- Transfer per second: bandwidth = lambda x average response size
- Cost of one resource: cost = quantity x unit price read from the provider's price page on a stated date
- Cost per unit of work: total cost of the period divided by the number of units of work in the period

## Headroom
Plan capacity from lambda_peak, not lambda. Keep a margin below the measured saturation point of the most limited resource. The size of the margin is a team decision recorded in an ADR and revisited after incidents.
