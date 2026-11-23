\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: join customers -> orders -> order_items.
-- TODO: return name, SUM(quantity * unit_price)::numeric(10,2) AS spent.
-- TODO: group by customer_id and name; order by customer_id.
