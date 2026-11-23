\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN;
UPDATE app.accounts SET balance = balance + 5 WHERE account_id = 1;
SELECT pg_sleep(3) \gset
UPDATE app.accounts SET balance = balance - 5 WHERE account_id = 2;
COMMIT;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
