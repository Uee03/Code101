DROP SCHEMA IF EXISTS app CASCADE;
DROP SCHEMA IF EXISTS tenant_acme CASCADE;
DROP SCHEMA IF EXISTS tenant_globex CASCADE;
DROP SCHEMA IF EXISTS tenant_initech CASCADE;
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
CREATE TABLE app.tenants (
    tenant_id integer NOT NULL,
    slug text NOT NULL,
    CONSTRAINT pk_tenants PRIMARY KEY (tenant_id),
    CONSTRAINT uq_tenants_slug UNIQUE (slug),
    CONSTRAINT ck_tenants_slug CHECK (slug ~ '^[a-z][a-z0-9_]{1,30}$')
);
INSERT INTO app.tenants (tenant_id, slug) VALUES (1, 'acme'), (2, 'globex');
CREATE TABLE app.projects (
    tenant_id integer NOT NULL,
    project_id integer NOT NULL,
    name text NOT NULL,
    CONSTRAINT pk_projects PRIMARY KEY (tenant_id, project_id),
    CONSTRAINT fk_projects_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenants (tenant_id)
);
CREATE TABLE app.tasks (
    tenant_id integer NOT NULL,
    task_id integer NOT NULL,
    project_id integer NOT NULL,
    title text NOT NULL,
    CONSTRAINT pk_tasks PRIMARY KEY (tenant_id, task_id),
    CONSTRAINT fk_tasks_project FOREIGN KEY (tenant_id, project_id)
        REFERENCES app.projects (tenant_id, project_id)
);
INSERT INTO app.projects (tenant_id, project_id, name) VALUES
    (1, 1, 'Launch'), (1, 2, 'Support'), (2, 1, 'Ops');
INSERT INTO app.tasks (tenant_id, task_id, project_id, title) VALUES
    (1, 1, 1, 'Pack'), (1, 2, 2, 'Answer'), (2, 1, 1, 'Deploy');
CREATE TABLE app.projects_naive (
    project_id integer NOT NULL,
    tenant_id integer NOT NULL,
    name text NOT NULL,
    CONSTRAINT pk_projects_naive PRIMARY KEY (project_id)
);
CREATE TABLE app.tasks_naive (
    task_id integer NOT NULL,
    tenant_id integer NOT NULL,
    project_id integer NOT NULL,
    title text NOT NULL,
    CONSTRAINT pk_tasks_naive PRIMARY KEY (task_id),
    CONSTRAINT fk_tasks_naive_project FOREIGN KEY (project_id) REFERENCES app.projects_naive (project_id)
);
INSERT INTO app.projects_naive (project_id, tenant_id, name) VALUES (1, 1, 'Launch'), (2, 2, 'Ops');
INSERT INTO app.tasks_naive (task_id, tenant_id, project_id, title) VALUES (1, 1, 1, 'Pack');
CREATE FUNCTION app.provision_tenant(p_slug text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    v_schema text;
BEGIN
    IF p_slug !~ '^[a-z][a-z0-9_]{1,30}$' THEN
        RAISE EXCEPTION 'invalid tenant slug' USING ERRCODE = '22023';
    END IF;
    v_schema := 'tenant_' || p_slug;
    EXECUTE format('CREATE SCHEMA %I', v_schema);
    EXECUTE format('CREATE TABLE %I.notes (note_id integer PRIMARY KEY, body text NOT NULL)', v_schema);
    RETURN v_schema;
END
$$;
CREATE FUNCTION app.add_note(p_slug text, p_note_id integer, p_body text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('INSERT INTO %I.notes (note_id, body) VALUES ($1, $2)', 'tenant_' || p_slug)
    USING p_note_id, p_body;
END
$$;
CREATE FUNCTION app.tenant_note_count(p_slug text) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE
    v_count bigint;
BEGIN
    EXECUTE format('SELECT count(*) FROM %I.notes', 'tenant_' || p_slug) INTO v_count;
    RETURN v_count;
END
$$;
CREATE FUNCTION app.add_column_everywhere(p_column text, p_type text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_schema text;
    v_count integer := 0;
BEGIN
    IF p_type NOT IN ('text', 'integer', 'boolean') THEN
        RAISE EXCEPTION 'type not allowed' USING ERRCODE = '22023';
    END IF;
    FOR v_schema IN SELECT nspname FROM pg_namespace WHERE starts_with(nspname, 'tenant_') ORDER BY nspname LOOP
        EXECUTE format('ALTER TABLE %I.notes ADD COLUMN %I %s', v_schema, p_column, p_type);
        v_count := v_count + 1;
    END LOOP;
    RETURN v_count;
END
$$;
