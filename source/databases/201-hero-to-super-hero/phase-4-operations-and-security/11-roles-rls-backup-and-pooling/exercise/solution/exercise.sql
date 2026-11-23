\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
BEGIN;
SET LOCAL ROLE db201_ben;
UPDATE app.tasks SET title = 'Restock safely' WHERE title = 'Restock';
SELECT title, owner_name FROM app.tasks ORDER BY task_id;
ROLLBACK;
