\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
BEGIN;
UPDATE app.tasks SET title = 'Pack safely' WHERE task_id = 1;
SELECT title, updated_at = CURRENT_TIMESTAMP AS timestamp_is_transaction_time
FROM app.tasks WHERE task_id = 1;
SELECT old_title, new_title, changed_by FROM app.task_audit ORDER BY audit_id;
UPDATE app.tasks SET title = title WHERE task_id = 1;
SELECT COUNT(*) AS audit_rows_after_noop FROM app.task_audit;
ROLLBACK;
SELECT title FROM app.tasks WHERE task_id = 1;
SELECT COUNT(*) AS audit_rows_after_rollback FROM app.task_audit;
