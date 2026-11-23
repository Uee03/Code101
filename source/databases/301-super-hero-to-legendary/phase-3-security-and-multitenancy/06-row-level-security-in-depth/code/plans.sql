\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '1';
EXPLAIN (ANALYZE, BUFFERS)
SELECT doc_id, title FROM app.documents WHERE title LIKE 'plan%';
COMMIT;
DROP POLICY documents_select ON app.documents;
CREATE POLICY documents_select ON app.documents FOR SELECT TO tenant_app
    USING (tenant_id = app.current_tenant());
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '1';
EXPLAIN (ANALYZE, BUFFERS)
SELECT doc_id, title FROM app.documents WHERE title LIKE 'plan%';
COMMIT;
