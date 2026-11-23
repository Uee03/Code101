\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
WITH ranked AS (
    SELECT team, rep, amount,
           row_number() OVER (PARTITION BY team ORDER BY amount DESC, sale_id) AS position
    FROM app.sales
)
SELECT team, rep, amount FROM ranked WHERE position = 1 ORDER BY team;
