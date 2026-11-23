\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT c.name, SUM(i.quantity * i.unit_price)::numeric(10,2) AS spent
FROM app.customers AS c
JOIN app.orders AS o USING (customer_id)
JOIN app.order_items AS i USING (order_id)
GROUP BY c.customer_id, c.name
ORDER BY c.customer_id;
