\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT app.estimated_rows('SELECT * FROM app.events WHERE status = ''open''') = 750 AS before_analyze_equals_750;
ANALYZE app.events;
SELECT app.estimated_rows('SELECT * FROM app.events WHERE status = ''open''') AS open_estimate,
       app.estimated_rows('SELECT * FROM app.events WHERE status = ''done''') AS done_estimate;
SELECT n_distinct, most_common_vals::text AS vals, most_common_freqs::text AS freqs
FROM pg_stats
WHERE schemaname = 'app' AND tablename = 'events' AND attname = 'status';
SELECT app.estimated_rows('SELECT * FROM app.events WHERE zone = 3 AND region = 0') AS estimate_without_extended,
       (SELECT count(*) FROM app.events WHERE zone = 3 AND region = 0) AS actual_rows;
CREATE STATISTICS app.st_events_zone_region (dependencies) ON zone, region FROM app.events;
ANALYZE app.events;
SELECT app.estimated_rows('SELECT * FROM app.events WHERE zone = 3 AND region = 0') AS estimate_with_dependencies;
SELECT current_setting('autovacuum') AS autovacuum_on,
       round(current_setting('autovacuum_vacuum_threshold')::numeric
             + current_setting('autovacuum_vacuum_scale_factor')::numeric * 1000) AS trigger_at_1000_rows,
       round(current_setting('autovacuum_vacuum_threshold')::numeric
             + current_setting('autovacuum_vacuum_scale_factor')::numeric * 10000000) AS trigger_at_10m_rows;
ALTER TABLE app.events SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 100);
SELECT option_name, option_value
FROM pg_options_to_table((SELECT reloptions FROM pg_class WHERE oid = 'app.events'::regclass))
ORDER BY option_name;
SELECT pg_relation_size('app.events') AS full_size \gset
DELETE FROM app.events WHERE event_id % 10 <> 0;
SELECT pg_relation_size('app.events') = :full_size AS size_after_delete_unchanged;
VACUUM app.events;
SELECT pg_relation_size('app.events') = :full_size AS size_after_vacuum_unchanged;
VACUUM FULL app.events;
SELECT pg_relation_size('app.events') < :full_size AS size_after_vacuum_full_smaller;
