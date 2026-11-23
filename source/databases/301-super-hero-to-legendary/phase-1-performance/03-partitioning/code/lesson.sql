\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT tableoid::regclass::text AS partition, count(*) AS rows
FROM app.measurements GROUP BY 1 ORDER BY 1;
SELECT app.partitions_in_plan('SELECT * FROM app.measurements') AS all_rows_query,
       app.partitions_in_plan('SELECT * FROM app.measurements WHERE recorded_on >= DATE ''2026-02-01'' AND recorded_on < DATE ''2026-03-01''') AS february_range,
       app.partitions_in_plan('SELECT * FROM app.measurements WHERE date_trunc(''month'', recorded_on) = TIMESTAMP ''2026-02-01 00:00:00''') AS wrapped_in_function;
SELECT tableoid::regclass::text AS partition, count(*) AS rows
FROM app.sales GROUP BY 1 ORDER BY 1;
SELECT count(*) AS total_rows,
       (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.sessions'::regclass) AS partitions
FROM app.sessions;
BEGIN;
SELECT app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (1000, 9, DATE ''2026-02-10'', 1.0)') AS in_range,
       app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (1001, 9, DATE ''2026-07-01'', 1.0)') AS out_of_range,
       app.attempt('CREATE UNIQUE INDEX ux_bad ON app.measurements (device_id)') AS unique_without_key;
ROLLBACK;
CREATE TABLE app.measurements_2026_04 (LIKE app.measurements INCLUDING DEFAULTS);
ALTER TABLE app.measurements_2026_04 ADD CONSTRAINT ck_measurements_2026_04
    CHECK (recorded_on >= DATE '2026-04-01' AND recorded_on < DATE '2026-05-01');
ALTER TABLE app.measurements ATTACH PARTITION app.measurements_2026_04
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading)
VALUES (7, 3, DATE '2026-04-02', 8.0);
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions_after_attach,
       (SELECT count(*) FROM app.measurements) AS rows_after_attach;
ALTER TABLE app.measurements DETACH PARTITION app.measurements_2026_04;
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions_after_detach,
       (SELECT count(*) FROM app.measurements) AS rows_after_detach,
       (SELECT count(*) FROM app.measurements_2026_04) AS detached_rows;
DROP TABLE app.measurements_2026_04;
