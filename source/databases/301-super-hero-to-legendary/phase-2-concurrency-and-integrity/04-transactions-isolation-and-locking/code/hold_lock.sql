\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN;
SELECT account_id AS locked_account FROM app.accounts WHERE account_id = 1 FOR UPDATE;
SELECT pg_sleep(12) \gset
COMMIT;
