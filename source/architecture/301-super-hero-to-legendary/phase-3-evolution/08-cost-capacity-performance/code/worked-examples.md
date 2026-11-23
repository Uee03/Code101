# Worked examples from the TDDs

Each example uses only numbers stated in a design document, and says which. None is a measurement of a running system.

## Example A: the per-user ceiling of the platform
Source: platform TDD, rate limits: 100 requests per 60 seconds per user.
- Sustained ceiling per user: 100 / 60 requests per second, which is about 1.67 requests per second.
- For U users all at their limit at once, the ceiling is U x 1.67 requests per second. This is an upper bound for planning the worst case, not an estimate of real traffic. Real traffic needs the measured inputs a, r and k from the worksheet.

## Example B: orders in flight in P07
Source: P07 non-functional requirements N-01 (20 orders per second sustained) and N-02 (p95 end-to-end confirmation under 2 seconds).
- Little's law: L = lambda x W.
- If every order took the full 2 seconds, L = 20 x 2 = 40 orders in flight at once.
- The true mean is normally lower than the p95 target, so 40 is a planning ceiling, provided the mean is not larger than the p95 target. Check this with measured data.

## Example C: broker traffic for the P07 load run
Sources: P07 N-01 and the saga diagram of lesson 03, which has four events on the success path: OrderPlaced, StockReserved, PaymentCaptured and ShipmentCreated.
- Orders in a 5-minute run: 20 x 300 = 6,000.
- Events on the success path per second: 20 x 4 = 80.
- Events in the run: 6,000 x 4 = 24,000.
- Failure paths and retries add more. The figures are a lower bound for the happy path.

## Example D: the shape of a cost estimate (no prices)
- Compute: instances x hours x price per instance-hour.
- Storage: gigabytes x months x price per gigabyte-month, multiplied by copies.
- Transfer: gigabytes out x price per gigabyte.
- Observability: log and trace volume x price per unit. This is often forgotten and can be large.
- People: hours of operation and on-call time.
Fill every price from the provider's price page on a dated check, and record the date.
