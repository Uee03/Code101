\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
INSERT INTO app.sales (team, amount) VALUES ('South', 7.00);
REFRESH MATERIALIZED VIEW app.cached_team_totals;
SELECT team, total FROM app.cached_team_totals ORDER BY team;
ROLLBACK;
