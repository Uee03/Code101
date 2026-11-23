# Async export design

| Question | Decision |
|---|---|
| Delivery guarantee | At least once; the worker may receive a job twice |
| How a repeated job is recognised | The job id is the key; a finished job is not run again, and the file name is derived from the job id so a rerun overwrites the same file |
| Tries and waiting time between tries | A small fixed number of tries with growing, randomised waits; the numbers are chosen from measuring how long failures last |
| What happens after the last try | The job moves to a dead-letter queue with the error and trace id, the status URL shows failed, and an operator is alerted |
| Ordering | Not needed; exports are independent of each other |
| What the message contains | The job id, the requesting user id and the filter; the file itself is written to storage |
| How the backlog is observed | Queue depth, age of the oldest job and dead-letter count as metrics |
