\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT count(*) AS superuser_sees FROM app.documents;
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '1';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (1, 'tenant 1 sees own rows', '2', (SELECT count(*)::text FROM app.documents));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (2, 'insert own tenant row', 'ok:1',
        app.attempt('INSERT INTO app.documents (doc_id, tenant_id, title) VALUES (10, 1, ''new-a'')'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (3, 'insert other tenant row', 'err:42501',
        app.attempt('INSERT INTO app.documents (doc_id, tenant_id, title) VALUES (11, 2, ''forged'')'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (4, 'update other tenant row', 'ok:0',
        app.attempt('UPDATE app.documents SET title = ''hacked'' WHERE doc_id = 3'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (5, 'move own row to other tenant', 'err:42501',
        app.attempt('UPDATE app.documents SET tenant_id = 2 WHERE doc_id = 1'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (6, 'delete other tenant row', 'ok:0',
        app.attempt('DELETE FROM app.documents WHERE doc_id = 4'));
SET LOCAL app.tenant_id = '';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (7, 'empty tenant context sees nothing', '0', (SELECT count(*)::text FROM app.documents));
SET LOCAL app.tenant_id = '2';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (8, 'forged tenant context is accepted', '2', (SELECT count(*)::text FROM app.documents));
RESET ROLE;
SELECT test_id, test, expected, actual, expected = actual AS pass FROM app.policy_tests ORDER BY test_id;
SELECT bool_and(expected = actual) AS all_policy_tests_pass FROM app.policy_tests;
ROLLBACK;
SELECT (SELECT proleakproof FROM pg_proc WHERE proname = 'int4eq') AS int4eq_leakproof,
       (SELECT proleakproof FROM pg_proc WHERE oid = 'app.current_tenant()'::regprocedure) AS own_function_leakproof;
SELECT count(*) AS rows_after_rollback FROM app.documents;
