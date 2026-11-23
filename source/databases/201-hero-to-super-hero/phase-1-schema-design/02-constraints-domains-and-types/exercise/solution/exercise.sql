\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
ALTER TABLE app.orders ADD CONSTRAINT ck_orders_quantity_limit CHECK (quantity <= 10);
SELECT bool_and(quantity <= 10) AS all_quantities_valid FROM app.orders;
