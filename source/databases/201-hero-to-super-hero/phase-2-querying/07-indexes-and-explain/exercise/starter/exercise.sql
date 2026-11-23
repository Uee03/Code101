\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: create ix_tasks_done_due on (project_id, due_on, task_id).
-- TODO: include title and use a partial predicate for done rows.
SELECT title FROM app.tasks WHERE project_id = 1 AND state = 'done' ORDER BY due_on, task_id;
