\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
BEGIN;
ALTER TABLE app.tasks ADD COLUMN due_on date;
SELECT title, due_on IS NULL AS starts_empty FROM app.tasks ORDER BY task_id;
ROLLBACK;
