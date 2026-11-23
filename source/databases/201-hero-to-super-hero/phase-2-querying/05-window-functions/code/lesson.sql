\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT team, rep, amount,
       row_number() OVER (PARTITION BY team ORDER BY amount DESC, sale_id) AS position,
       rank() OVER (PARTITION BY team ORDER BY amount DESC) AS place,
       dense_rank() OVER (PARTITION BY team ORDER BY amount DESC) AS dense_place,
       SUM(amount) OVER (
           PARTITION BY team ORDER BY sold_on, sale_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_amount,
       lag(amount, 1, 0) OVER (PARTITION BY team ORDER BY sold_on, sale_id) AS previous_amount
FROM app.sales ORDER BY team, sold_on, sale_id;
