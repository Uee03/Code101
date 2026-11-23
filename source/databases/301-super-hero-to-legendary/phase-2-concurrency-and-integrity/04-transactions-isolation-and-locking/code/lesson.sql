\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT current_setting('transaction_isolation') AS default_isolation;
WITH next AS (
    SELECT job_id FROM app.jobs WHERE state = 'pending' ORDER BY job_id LIMIT 1 FOR UPDATE SKIP LOCKED
)
UPDATE app.jobs AS j SET state = 'running' FROM next WHERE j.job_id = next.job_id RETURNING j.job_id AS claimed_job;
WITH next AS (
    SELECT job_id FROM app.jobs WHERE state = 'pending' ORDER BY job_id LIMIT 1 FOR UPDATE SKIP LOCKED
)
UPDATE app.jobs AS j SET state = 'running' FROM next WHERE j.job_id = next.job_id RETURNING j.job_id AS claimed_job;
BEGIN;
SELECT pg_try_advisory_xact_lock(42) AS first_try, pg_try_advisory_xact_lock(42) AS second_try_same_session;
SELECT count(*) AS advisory_locks_held FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid();
COMMIT;
SELECT count(*) AS advisory_locks_after_commit FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid();
SELECT app.attempt('SELECT app.transfer(1, 2, 30)') AS transfer_30;
SELECT app.attempt('SELECT app.transfer(1, 2, 500)') AS transfer_500;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
