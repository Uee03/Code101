\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '2';
-- TODO: replace 'TODO' below with the actual result of app.attempt for deleting doc_id 4 (tenant 2's own row).
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (1, 'tenant 2 deletes own row', 'ok:1', 'TODO');
-- TODO: add test 2, named 'tenant 2 cannot see tenant 1 row', expecting '0', whose actual value is the number
-- of rows with doc_id = 1 that tenant 2 can see (as text). Use the same INSERT shape as test 1.
RESET ROLE;
SELECT test_id, test, expected, actual, expected = actual AS pass FROM app.policy_tests ORDER BY test_id;
ROLLBACK;
