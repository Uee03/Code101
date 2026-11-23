\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA IF NOT EXISTS app;
CREATE TABLE IF NOT EXISTS app.schema_migrations (
    version text,
    CONSTRAINT pk_schema_migrations PRIMARY KEY (version)
);
LOCK TABLE app.schema_migrations IN EXCLUSIVE MODE;
SELECT NOT EXISTS (SELECT 1 FROM app.schema_migrations WHERE version = '001') AS apply_001
\gset
\if :apply_001
    \ir migrations/001_create_tasks.sql
    INSERT INTO app.schema_migrations (version) VALUES ('001');
\endif
SELECT NOT EXISTS (SELECT 1 FROM app.schema_migrations WHERE version = '002') AS apply_002
\gset
\if :apply_002
    \ir migrations/002_add_priority.sql
    INSERT INTO app.schema_migrations (version) VALUES ('002');
\endif
COMMIT;
