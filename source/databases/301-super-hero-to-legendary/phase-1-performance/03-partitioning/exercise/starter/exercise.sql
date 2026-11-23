\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: create app.measurements_2026_05 as a partition of app.measurements for May 2026
-- (from 2026-05-01 up to, but not including, 2026-06-01).
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions,
       app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (50, 1, DATE ''2026-05-10'', 2.0)') AS may_insert;
