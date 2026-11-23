\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
-- TODO: insert a South sale for 7.00.
-- TODO: refresh app.cached_team_totals (ordinary refresh is enough here).
-- TODO: return team and total in team order from the materialized view.
ROLLBACK;
