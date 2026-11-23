\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
BEGIN;
UPDATE bank.accounts SET balance = balance - 25 WHERE account_id = 1;
UPDATE bank.accounts SET balance = balance + 25 WHERE account_id = 2;
COMMIT;
SELECT owner, balance FROM bank.accounts ORDER BY account_id;
BEGIN;
UPDATE bank.accounts SET balance = balance - 10 WHERE account_id = 1;
ROLLBACK;
SELECT owner, balance FROM bank.accounts ORDER BY account_id;
