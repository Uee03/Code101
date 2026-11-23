\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
SET TIME ZONE 'UTC';
\ir /scripts/setup.sql
SELECT count(*) AS january_orders FROM app.orders
WHERE placed_at >= TIMESTAMPTZ '2026-01-01 00:00:00+00' AND placed_at < TIMESTAMPTZ '2026-02-01 00:00:00+00';
