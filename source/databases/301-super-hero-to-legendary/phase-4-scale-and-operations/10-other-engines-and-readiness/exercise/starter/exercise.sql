\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: write a query that returns the check name 'float_money' and the object name (schema.table.column)
-- of every column in schema app whose type is double precision or real and whose name contains
-- total, price, amount or balance. Use the same catalog joins as the checks in lesson.sql.
SELECT 'float_money' AS check_name, NULL AS object;
