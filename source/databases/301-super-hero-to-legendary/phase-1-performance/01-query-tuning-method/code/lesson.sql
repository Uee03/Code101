\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
SET TIME ZONE 'UTC';
\ir setup.sql
SELECT pg_stat_statements_reset() IS NOT NULL AS stats_cleared;
\o /dev/null
SELECT count(*) FROM app.orders WHERE customer_id = 7;
SELECT count(*) FROM app.orders WHERE customer_id = 8;
SELECT count(*) FROM app.orders WHERE customer_id = 9;
SELECT order_id FROM app.orders WHERE customer_id = 7 ORDER BY order_id;
SELECT order_id FROM app.orders WHERE customer_id = 8 ORDER BY order_id;
\o
SELECT calls, rows,
       CASE WHEN query LIKE 'SELECT count(*)%' THEN 'count per customer' ELSE 'ids per customer' END AS shape
FROM pg_stat_statements
WHERE query LIKE '%FROM app.orders%' AND query NOT LIKE '%pg_stat_statements%'
ORDER BY shape;
SELECT count(*) AS wrapped_filter FROM app.orders
WHERE date_trunc('day', placed_at) = TIMESTAMPTZ '2026-01-02 00:00:00+00';
SELECT count(*) AS range_filter FROM app.orders
WHERE placed_at >= TIMESTAMPTZ '2026-01-02 00:00:00+00' AND placed_at < TIMESTAMPTZ '2026-01-03 00:00:00+00';
SELECT string_agg(order_id::text, ',' ORDER BY order_id) AS offset_page
FROM (SELECT order_id FROM app.orders ORDER BY order_id OFFSET 995 LIMIT 5) AS p;
SELECT string_agg(order_id::text, ',' ORDER BY order_id) AS keyset_page
FROM (SELECT order_id FROM app.orders WHERE order_id > 995 ORDER BY order_id LIMIT 5) AS p;
