# Load test and measurement plan

This is a plan to fill in before a test. It is a template; nothing here has been run.

| Section | What to write |
|---|---|
| Question | The single question the test answers, for example: does the p95 stay within the target at the planned rate? |
| Workload model | The mix of operations and their proportions, taken from real traffic logs |
| Data | Volume and shape of test data, close to production size |
| Environment | How it differs from production, and what that means for the result |
| Ramp | How the load rises, holds and falls |
| Metrics | Latency percentiles, error rate, throughput, and saturation of every resource |
| Pass criteria | Written before the test, tied to the service level objective or to a scenario |
| Stop conditions | When to stop to protect shared systems |
| Report | Percentiles not averages, the saturation point, the limiting resource, the difference from the prediction |

Rules:
- Test one change at a time.
- Repeat a test before trusting a surprising result.
- Never publish a number without its conditions: environment, data size, load shape and date.
- Keep fakes and partner stubs realistic; a stub that always answers instantly hides the slow partner problem.
