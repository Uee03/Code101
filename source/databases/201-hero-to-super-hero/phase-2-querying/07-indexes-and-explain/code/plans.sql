\set ON_ERROR_STOP on
EXPLAIN (COSTS OFF)
SELECT task_id, title, due_on FROM app.tasks
WHERE project_id = 1 AND state = 'open' ORDER BY due_on, task_id;
EXPLAIN (ANALYZE, BUFFERS)
SELECT task_id, title, due_on FROM app.tasks
WHERE project_id = 1 AND state = 'open' ORDER BY due_on, task_id;
EXPLAIN (COSTS OFF)
SELECT task_id FROM app.tasks WHERE metadata @> '{"priority":"high"}'::jsonb;
