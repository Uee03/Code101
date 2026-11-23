\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '2';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (1, 'tenant 2 deletes own row', 'ok:1', app.attempt('DELETE FROM app.documents WHERE doc_id = 4'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (2, 'tenant 2 cannot see tenant 1 row', '0',
        (SELECT count(*)::text FROM app.documents WHERE doc_id = 1));
RESET ROLE;
SELECT test_id, test, expected, actual, expected = actual AS pass FROM app.policy_tests ORDER BY test_id;
ROLLBACK;
