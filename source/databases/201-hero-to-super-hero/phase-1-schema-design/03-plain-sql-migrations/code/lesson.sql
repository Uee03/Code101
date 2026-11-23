\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir migrate.sql
\ir migrate.sql
SELECT version FROM app.schema_migrations ORDER BY version;
SELECT task_id, title, priority FROM app.tasks ORDER BY task_id;
