\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
UPDATE app.tasks SET title = 'Ready' WHERE task_id = 1;
UPDATE app.tasks SET title = 'Dispatched' WHERE task_id = 1;
SELECT old_title, new_title FROM app.task_audit ORDER BY audit_id;
ROLLBACK;
