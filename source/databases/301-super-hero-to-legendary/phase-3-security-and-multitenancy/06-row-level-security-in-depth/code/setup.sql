DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tenant_app') THEN
        CREATE ROLE tenant_app NOLOGIN;
    END IF;
END
$$;
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE FUNCTION app.attempt(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    v_rows bigint;
BEGIN
    EXECUTE p_sql;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN 'ok:' || v_rows;
EXCEPTION WHEN OTHERS THEN
    RETURN 'err:' || SQLSTATE;
END
$$;
CREATE FUNCTION app.current_tenant() RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT nullif(current_setting('app.tenant_id', true), '')::integer
$$;
CREATE TABLE app.documents (
    doc_id integer NOT NULL,
    tenant_id integer NOT NULL,
    title text NOT NULL,
    CONSTRAINT pk_documents PRIMARY KEY (doc_id)
);
CREATE INDEX ix_documents_tenant ON app.documents (tenant_id);
INSERT INTO app.documents (doc_id, tenant_id, title) VALUES
    (1, 1, 'plan-a'),
    (2, 1, 'budget-a'),
    (3, 2, 'plan-g'),
    (4, 2, 'secret-g');
CREATE TABLE app.policy_tests (
    test_id integer NOT NULL,
    test text NOT NULL,
    expected text NOT NULL,
    actual text NOT NULL,
    CONSTRAINT pk_policy_tests PRIMARY KEY (test_id)
);
ALTER TABLE app.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.documents FORCE ROW LEVEL SECURITY;
CREATE POLICY documents_select ON app.documents FOR SELECT TO tenant_app
    USING (tenant_id = (SELECT app.current_tenant()));
CREATE POLICY documents_insert ON app.documents FOR INSERT TO tenant_app
    WITH CHECK (tenant_id = (SELECT app.current_tenant()));
CREATE POLICY documents_update ON app.documents FOR UPDATE TO tenant_app
    USING (tenant_id = (SELECT app.current_tenant()))
    WITH CHECK (tenant_id = (SELECT app.current_tenant()));
CREATE POLICY documents_delete ON app.documents FOR DELETE TO tenant_app
    USING (tenant_id = (SELECT app.current_tenant()));
GRANT USAGE ON SCHEMA app TO tenant_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.documents TO tenant_app;
GRANT INSERT ON app.policy_tests TO tenant_app;
