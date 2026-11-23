\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT o.order_id, c.name, SUM(i.quantity * i.unit_price)::numeric(10,2) AS total
FROM app.orders AS o
JOIN app.customers AS c USING (customer_id)
JOIN app.order_items AS i USING (order_id)
GROUP BY o.order_id, c.name
ORDER BY o.order_id;
BEGIN;
UPDATE app.products SET current_price = 6.00 WHERE product_id = 1;
SELECT SUM(quantity * unit_price)::numeric(10,2) AS historical_total
FROM app.order_items;
ROLLBACK;
