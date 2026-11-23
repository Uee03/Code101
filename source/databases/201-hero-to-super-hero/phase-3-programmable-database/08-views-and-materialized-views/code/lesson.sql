\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT 'initial' AS stage, v.total AS live_total, m.total AS cached_total
FROM app.team_totals AS v JOIN app.cached_team_totals AS m USING (team)
WHERE v.team = 'North';
UPDATE app.sales SET amount = 15.00 WHERE sale_id = 1;
SELECT 'changed' AS stage, v.total AS live_total, m.total AS cached_total
FROM app.team_totals AS v JOIN app.cached_team_totals AS m USING (team)
WHERE v.team = 'North';
REFRESH MATERIALIZED VIEW CONCURRENTLY app.cached_team_totals;
SELECT 'refreshed' AS stage, v.total AS live_total, m.total AS cached_total
FROM app.team_totals AS v JOIN app.cached_team_totals AS m USING (team)
WHERE v.team = 'North';
