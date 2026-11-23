\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
-- Prerequisite: Run it has created the roles and seed once.
BEGIN;
SET LOCAL ROLE db201_ben;
-- TODO: update Ben's visible task title to Restock safely.
-- TODO: return title, owner_name in task_id order.
ROLLBACK;
