\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
-- Prerequisite: Run it has applied migrations 001 and 002.
BEGIN;
-- TODO: add nullable due_on date to app.tasks.
-- TODO: return title and due_on IS NULL AS starts_empty.
ROLLBACK;
