\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT task_id, title, due_on FROM app.tasks
WHERE project_id = 1 AND state = 'open'
ORDER BY due_on, task_id;
SELECT task_id FROM app.tasks
WHERE metadata @> '{"priority":"high"}'::jsonb ORDER BY task_id;
