\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
SELECT category, SUM(quantity * unit_price) AS revenue
FROM practice.sales GROUP BY category
HAVING SUM(quantity * unit_price) >= 12 ORDER BY category;
