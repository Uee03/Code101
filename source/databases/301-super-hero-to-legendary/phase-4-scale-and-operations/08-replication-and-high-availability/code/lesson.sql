\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT name, setting FROM pg_settings
WHERE name IN ('wal_level', 'max_wal_senders', 'max_replication_slots', 'archive_mode',
               'synchronous_commit', 'hot_standby', 'fsync', 'full_page_writes')
ORDER BY name;
SELECT pg_is_in_recovery() AS in_recovery, (SELECT count(*) FROM pg_stat_replication) AS standbys_connected;
SELECT pg_current_wal_lsn() AS lsn_before \gset
INSERT INTO app.orders (order_id, customer, total_cents) VALUES (4, 'di', 500);
SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), :'lsn_before') > 0 AS wal_advanced;
SELECT slot_name FROM pg_create_physical_replication_slot('code101_slot');
SELECT slot_name, slot_type, active FROM pg_replication_slots;
SELECT pg_drop_replication_slot('code101_slot') \gset
SELECT count(*) AS slots_after_drop FROM pg_replication_slots;
CREATE PUBLICATION pub_orders FOR TABLE app.orders, app.audit_events;
SELECT pubname, pubinsert, pubupdate, pubdelete FROM pg_publication;
SELECT app.attempt('UPDATE app.audit_events SET event = ''renamed''') AS update_without_identity;
ALTER TABLE app.audit_events REPLICA IDENTITY FULL;
SELECT app.attempt('UPDATE app.audit_events SET event = ''renamed''') AS update_with_full_identity;
DROP PUBLICATION pub_orders;
SELECT count(*) AS orders, sum(total_cents) AS total_cents, max(order_id) AS last_order FROM app.orders;
