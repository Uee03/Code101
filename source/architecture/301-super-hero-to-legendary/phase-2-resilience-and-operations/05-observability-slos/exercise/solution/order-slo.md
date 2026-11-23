# SLO for P07: orders reach a final state

| Field | Content |
|---|---|
| Service and user journey | Chloe places an order and it ends as confirmed or cancelled without manual repair |
| SLI: good events | Orders that reach confirmed or cancelled within the end-to-end time target |
| SLI: valid events | Orders accepted by the gateway with a valid request, excluding orders sent while a drill injects faults on purpose |
| Where it is measured | In the order view, from the recorded state changes and their times |
| Window | A rolling window agreed with the shop owner |
| SLO target | A proposal to confirm after a load test. P07 N-02 gives the starting latency idea: p95 under 2 seconds at 20 orders per second with healthy fakes |
| Exclusions | Orders placed during announced chaos drills, and orders cancelled by the customer |
| Error budget | One minus the target, counted in orders |
