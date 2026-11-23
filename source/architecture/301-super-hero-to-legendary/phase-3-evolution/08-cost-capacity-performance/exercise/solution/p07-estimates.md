# P07 estimates from the design documents

Use only numbers stated in the P07 TDD. Write the formula, the result and the source.

| Quantity | Formula | Result | Source numbers |
|---|---|---|---|
| Orders created in a 5-minute run at 20 orders per second | 20 x 300 | 6,000 | N-01 |
| Outbox rows written by Orders in that run, if each order writes one | 6,000 x 1 | 6,000 | R-03 |
| Orders in flight if each order takes the full 2 seconds | 20 x 2 | 40 | N-01, N-02 |
| Stock reservations that fail when 200 parallel orders compete for 50 units | 200 - 50 | 150 | R-06 |

What would you measure to replace the "if" in the third row with a real figure?
The mean time from order placed to a final state, from the recorded state changes, at the planned rate; compare it with the p95 target to check that the mean is not larger.
