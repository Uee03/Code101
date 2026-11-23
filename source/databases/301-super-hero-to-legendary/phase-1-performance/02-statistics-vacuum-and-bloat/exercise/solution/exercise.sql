\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT round(50 + 0.2 * 250000) AS default_trigger, round(50 + 0.01 * 250000) AS tuned_trigger;
