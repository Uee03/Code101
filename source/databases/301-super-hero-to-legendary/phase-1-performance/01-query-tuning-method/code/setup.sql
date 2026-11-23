DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    customer_id integer NOT NULL,
    status text NOT NULL,
    total_cents integer NOT NULL,
    placed_at timestamptz NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);
INSERT INTO app.orders (customer_id, status, total_cents, placed_at)
SELECT 1 + (n % 10),
       CASE WHEN n % 20 = 0 THEN 'cancelled' ELSE 'paid' END,
       1000 + n,
       TIMESTAMPTZ '2026-01-01 00:00:00+00' + n * INTERVAL '1 hour'
FROM generate_series(1, 1000) AS n;
ANALYZE app.orders;
