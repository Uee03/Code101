\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: replace both NULL values with the autovacuum trigger point for a 250000-row table.
-- Formula: threshold + scale_factor * rows. Default is 50 + 0.2 * rows; the tuned table uses 50 + 0.01 * rows.
-- Round each result to a whole number.
SELECT NULL AS default_trigger, NULL AS tuned_trigger;
