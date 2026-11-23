\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
UPDATE app.accounts SET balance = balance - 50 WHERE account_id = 1;
SELECT balance AS b_final FROM app.accounts WHERE account_id = 1;
