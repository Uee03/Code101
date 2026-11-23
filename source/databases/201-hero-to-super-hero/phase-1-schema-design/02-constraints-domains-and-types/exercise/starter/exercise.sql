\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: add a named CHECK enforcing quantity <= 10 on app.orders.
-- TODO: show whether every existing quantity is <= 10 using bool_and.
