\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE INDEX ix_tasks_done_due ON app.tasks (project_id, due_on, task_id)
    INCLUDE (title) WHERE state = 'done';
SELECT title FROM app.tasks WHERE project_id = 1 AND state = 'done' ORDER BY due_on, task_id;
