\set ON_ERROR_STOP off
\pset format unaligned
\pset footer off
SELECT account_id AS nowait_result FROM app.accounts WHERE account_id = 1 FOR UPDATE NOWAIT;
SELECT account_id AS skip_locked_result FROM app.accounts WHERE account_id = 1 FOR UPDATE SKIP LOCKED;
SELECT account_id AS other_row FROM app.accounts WHERE account_id = 2 FOR UPDATE NOWAIT;
SET lock_timeout = '1s';
UPDATE app.accounts SET balance = balance WHERE account_id = 1;
