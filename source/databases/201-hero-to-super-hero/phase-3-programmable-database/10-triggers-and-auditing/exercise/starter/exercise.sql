\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
-- TODO: change title to Ready, then Dispatched for task 1.
-- TODO: select old_title, new_title ordered by audit_id.
ROLLBACK;
