\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
SELECT COUNT(*) AS sale_rows, SUM(quantity) AS items_sold,
       ROUND(AVG(unit_price), 2) AS average_price FROM practice.sales;
SELECT category, COUNT(*) AS sale_rows, SUM(quantity) AS items_sold,
       SUM(quantity * unit_price) AS revenue
FROM practice.sales GROUP BY category
HAVING SUM(quantity) >= 3 ORDER BY category;
