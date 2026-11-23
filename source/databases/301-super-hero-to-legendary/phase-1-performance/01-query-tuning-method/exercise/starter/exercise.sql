\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
SET TIME ZONE 'UTC';
\ir /scripts/setup.sql
-- TODO: rewrite the filter as a half-open range on placed_at (no function on the column).
-- The range must start at 2026-01-01 00:00:00+00 and end before 2026-02-01 00:00:00+00.
SELECT count(*) AS january_orders FROM app.orders
WHERE date_trunc('month', placed_at) = TIMESTAMPTZ '2026-01-01 00:00:00+00';
