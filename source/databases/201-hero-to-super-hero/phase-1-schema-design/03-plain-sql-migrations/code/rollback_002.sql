\set ON_ERROR_STOP on
BEGIN;
LOCK TABLE app.schema_migrations IN EXCLUSIVE MODE;
ALTER TABLE app.tasks DROP CONSTRAINT ck_tasks_priority;
ALTER TABLE app.tasks DROP COLUMN priority;
DELETE FROM app.schema_migrations WHERE version = '002';
COMMIT;
