\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE TABLE app.measurements_2026_05 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions,
       app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (50, 1, DATE ''2026-05-10'', 2.0)') AS may_insert;
