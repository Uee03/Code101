\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
\o /dev/null
-- TODO: create a physical replication slot named exercise_slot that reserves WAL immediately.
-- Pass true as the second argument (immediately_reserve).
SELECT pg_create_physical_replication_slot('exercise_slot');
\o
SELECT slot_name, active, restart_lsn IS NOT NULL AS retains_wal FROM pg_replication_slots;
SELECT pg_drop_replication_slot('exercise_slot') \gset
