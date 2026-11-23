\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
SELECT COUNT(*) AS total_rows FROM app.tasks;
SET ROLE db201_ava;
SELECT title, owner_name FROM app.tasks ORDER BY task_id;
RESET ROLE;
