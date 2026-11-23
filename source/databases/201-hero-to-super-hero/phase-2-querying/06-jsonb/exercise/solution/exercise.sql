\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT sku FROM app.products
WHERE attributes @> '{"ink":"blue"}'::jsonb ORDER BY product_id;
