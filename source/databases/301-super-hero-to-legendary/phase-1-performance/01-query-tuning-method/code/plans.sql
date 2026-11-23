\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
DROP INDEX IF EXISTS app.ix_orders_customer;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id FROM app.orders WHERE customer_id = 7 ORDER BY order_id;
CREATE INDEX ix_orders_customer ON app.orders (customer_id, order_id);
ANALYZE app.orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id FROM app.orders WHERE customer_id = 7 ORDER BY order_id;
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM app.orders
WHERE date_trunc('day', placed_at) = TIMESTAMPTZ '2026-01-02 00:00:00+00';
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM app.orders
WHERE placed_at >= TIMESTAMPTZ '2026-01-02 00:00:00+00' AND placed_at < TIMESTAMPTZ '2026-01-03 00:00:00+00';
