# Runbook: orders database unavailable

Owner: platform on-call
Last tested: record the date of your drill here
Severity guide: S1 customers cannot place orders; S2 reads work, writes fail; S3 slow queries.

## Symptoms
- The orders service reports connection errors or health checks fail.
- `docker compose ps` shows the `db` service as unhealthy, restarting or exited.

## Impact and urgency
- No orders can be created or read while the database is down.
- Every minute adds to lost orders: escalate at once if not back within 15 minutes.

## First checks (2 minutes)
1. `docker compose ps` shows the state and the health of `db`.
2. `docker compose logs --tail 100 db` shows the last errors.
3. `docker system df` shows whether the disk is full (a full disk is a common cause).

## Mitigate
1. If the container exited or is unhealthy and the disk is not full: `docker compose restart db`, then check `docker compose ps` again.
2. If the disk is full: free space (old logs, unused images) without touching the `pgdata` volume, then restart as above.
3. If the data is damaged or lost: restore from the latest backup (see Recover below) and tell the owner how much data was lost.
4. If none of these works within 30 minutes: escalate.

## Recover from a backup
1. Prove the backup restores: `docker compose exec db sh /scripts/restore-drill.sh` must end with `drill passed`.
2. Restore over the live database: `docker compose exec db sh /scripts/recover-latest.sh`.
3. Count the rows in the key tables and compare with the last known value.

## Verify recovery
- `docker compose ps` shows `db` as healthy.
- The orders service health check passes and an order can be created and read back.
- Watch the error rate for 30 minutes.

## Escalate
- The database owner, then the engineering manager. Record who was called and when.

## Afterwards
- Write a blameless review within five working days.
- Record the data-loss window: the time between the last good backup and the failure.
