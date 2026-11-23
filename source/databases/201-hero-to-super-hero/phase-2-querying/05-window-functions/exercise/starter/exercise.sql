\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
WITH ranked AS (
    SELECT team, rep, amount,
           -- TODO: number each team's rows by amount descending, then sale_id.
           0 AS position
    FROM app.sales
)
-- TODO: keep position 1 and order by team.
SELECT team, rep, amount FROM ranked WHERE false ORDER BY team;
