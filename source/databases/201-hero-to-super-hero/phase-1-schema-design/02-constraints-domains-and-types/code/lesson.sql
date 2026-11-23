\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT order_id, state, quantity FROM app.orders ORDER BY order_id;
SELECT ('-1'::numeric >= 0) AS negative_passes_check,
       (NULL::numeric >= 0) IS NULL AS null_check_is_unknown;
WITH quotes AS (
    SELECT ROW(sku, price)::app.price_quote AS quote FROM app.products
)
SELECT (quote).sku AS sku, (quote).amount AS amount
FROM quotes ORDER BY (quote).sku;
