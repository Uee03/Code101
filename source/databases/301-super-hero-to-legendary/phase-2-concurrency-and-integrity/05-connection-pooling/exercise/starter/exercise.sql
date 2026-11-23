\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: insert a service 'reports' with 2 instances and a pool of 8 connections per instance.
-- TODO: replace both NULL values. demand is the sum of instances * pool_per_instance over all services.
-- fits compares demand with 97 - 10 (available connections minus the operations reserve).
SELECT NULL AS demand, NULL AS fits;
