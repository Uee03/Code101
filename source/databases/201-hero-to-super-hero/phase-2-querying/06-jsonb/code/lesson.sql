\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT sku, attributes ->> 'color' AS color,
       attributes -> 'gift_note' IS NULL AS note_missing,
       attributes ? 'gift_note' AS has_note_key
FROM app.products ORDER BY product_id;
SELECT sku FROM app.products
WHERE attributes @> '{"tags":["gift"]}'::jsonb ORDER BY product_id;
SELECT sku, (attributes ->> 'pages')::integer AS pages
FROM app.products WHERE attributes ? 'pages' ORDER BY product_id;
