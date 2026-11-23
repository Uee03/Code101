\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SET ROLE db201_ava;
SELECT title, owner_name FROM app.tasks ORDER BY task_id;
SELECT COUNT(*) AS hidden_ben_rows FROM app.tasks WHERE owner_name = 'db201_ben';
UPDATE app.tasks SET title = 'stolen' WHERE owner_name = 'db201_ben';
DO $$
BEGIN
    BEGIN
        INSERT INTO app.tasks (owner_name, title) VALUES ('db201_ben', 'forbidden');
        RAISE EXCEPTION 'cross-owner insert unexpectedly allowed';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
    BEGIN
        DELETE FROM app.tasks;
        RAISE EXCEPTION 'delete unexpectedly allowed';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;
SELECT 'blocked' AS cross_owner_insert, 'blocked' AS delete_without_grant;
RESET ROLE;
SET ROLE db201_ben;
SELECT title, owner_name FROM app.tasks ORDER BY task_id;
RESET ROLE;
