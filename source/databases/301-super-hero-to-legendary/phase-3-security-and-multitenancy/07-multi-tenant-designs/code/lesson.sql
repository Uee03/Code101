\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT tenant_id, count(*) AS tasks FROM app.tasks GROUP BY tenant_id ORDER BY tenant_id;
BEGIN;
SELECT app.attempt('INSERT INTO app.tasks (tenant_id, task_id, project_id, title) VALUES (2, 2, 2, ''Cross'')') AS composite_fk_blocks_cross_tenant,
       app.attempt('INSERT INTO app.tasks_naive (task_id, tenant_id, project_id, title) VALUES (2, 2, 1, ''Cross'')') AS single_column_fk_allows_it;
ROLLBACK;
SELECT app.provision_tenant('acme') AS schema_1,
       app.provision_tenant('globex') AS schema_2,
       app.provision_tenant('initech') AS schema_3;
\o /dev/null
SELECT app.add_note('acme', 1, 'welcome'), app.add_note('acme', 2, 'plan'), app.add_note('globex', 1, 'hello');
\o
SELECT t.slug, app.tenant_note_count(t.slug) AS notes
FROM (VALUES ('acme'), ('globex'), ('initech')) AS t(slug)
ORDER BY t.slug;
SELECT app.attempt('SELECT app.provision_tenant(''bad; drop'')') AS bad_slug;
SELECT app.add_column_everywhere('pinned', 'boolean') AS schemas_altered;
SELECT count(*) AS notes_tables_with_pinned FROM information_schema.columns
WHERE column_name = 'pinned' AND table_name = 'notes' AND starts_with(table_schema, 'tenant_');
SELECT (SELECT count(*) FROM pg_namespace WHERE starts_with(nspname, 'tenant_')) AS tenant_schemas,
       (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE starts_with(n.nspname, 'tenant_') AND c.relkind IN ('r', 'i')) AS catalog_relations;
