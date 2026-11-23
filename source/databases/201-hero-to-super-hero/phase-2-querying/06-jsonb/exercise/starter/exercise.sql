\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: return sku for documents containing the ink key with value blue.
-- TODO: use @> on attributes, then order by product_id.
SELECT sku FROM app.products WHERE false ORDER BY product_id;
