\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
-- TODO: this is session B of the deadlock demo. It moves 5 from account 2 to account 1 but locks
-- account 2 first. Reorder the two UPDATE statements so that account 1 is always locked first.
-- Keep the same arithmetic: account 2 loses 5 and account 1 gains 5.
BEGIN;
UPDATE app.accounts SET balance = balance - 5 WHERE account_id = 2;
SELECT pg_sleep(3) \gset
UPDATE app.accounts SET balance = balance + 5 WHERE account_id = 1;
COMMIT;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
