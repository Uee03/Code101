\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN ISOLATION LEVEL :iso;
SELECT balance AS seen FROM app.accounts WHERE account_id = 1 \gset
SELECT pg_sleep(6) \gset
UPDATE app.accounts SET balance = :seen - 30 WHERE account_id = 1;
COMMIT;
SELECT balance AS a_final FROM app.accounts WHERE account_id = 1;
