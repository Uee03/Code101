-- Tasks and Teams: PostgreSQL 17 schema. Run once on an empty database.
-- Disposable local role for the backends; create it from a secret store in any real environment.
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tasks_app') THEN
        CREATE ROLE tasks_app LOGIN PASSWORD 'tasks_app_local_only';
    END IF;
END
$$;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Tables ---------------------------------------------------------------------

CREATE TABLE users (
    id           uuid PRIMARY KEY,
    username     text        NOT NULL CHECK (length(btrim(username)) BETWEEN 1 AND 100),
    email        text        NOT NULL CHECK (position('@' IN email) > 1),
    display_name text        NOT NULL CHECK (length(btrim(display_name)) BETWEEN 1 AND 120),
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_username_key ON users (lower(username));
CREATE UNIQUE INDEX users_email_key ON users (lower(email));

CREATE TABLE teams (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text        NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 80),
    description text        NOT NULL DEFAULT '' CHECK (length(description) <= 500),
    created_by  uuid        NOT NULL REFERENCES users (id),
    version     integer     NOT NULL DEFAULT 1,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX teams_name_key ON teams (lower(name));
CREATE INDEX teams_created_idx ON teams (created_at DESC, id DESC);

CREATE TABLE team_members (
    team_id   uuid        NOT NULL REFERENCES teams (id) ON DELETE CASCADE,
    user_id   uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role      text        NOT NULL DEFAULT 'member' CHECK (role IN ('lead', 'member')),
    joined_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (team_id, user_id)
);
CREATE INDEX team_members_user_idx ON team_members (user_id);

CREATE TABLE projects (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id     uuid        NOT NULL REFERENCES teams (id) ON DELETE CASCADE,
    key         text        NOT NULL CHECK (key ~ '^[A-Z][A-Z0-9]{1,9}$'),
    name        text        NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 120),
    description text        NOT NULL DEFAULT '' CHECK (length(description) <= 2000),
    archived    boolean     NOT NULL DEFAULT false,
    created_by  uuid        NOT NULL REFERENCES users (id),
    version     integer     NOT NULL DEFAULT 1,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (team_id, key)
);
CREATE INDEX projects_team_created_idx ON projects (team_id, created_at DESC, id DESC);

CREATE TABLE tasks (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id   uuid        NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    title        text        NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 200),
    description  text        NOT NULL DEFAULT '' CHECK (length(description) <= 10000),
    status       text        NOT NULL DEFAULT 'todo'
                 CHECK (status IN ('todo', 'in_progress', 'blocked', 'done', 'cancelled')),
    priority     text        NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    assignee_id  uuid        REFERENCES users (id) ON DELETE SET NULL,
    due_date     date,
    completed_at timestamptz,
    created_by   uuid        NOT NULL REFERENCES users (id),
    version      integer     NOT NULL DEFAULT 1,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CHECK ((status = 'done') = (completed_at IS NOT NULL))
);
CREATE INDEX tasks_project_created_idx ON tasks (project_id, created_at DESC, id DESC);
CREATE INDEX tasks_project_status_idx ON tasks (project_id, status);
CREATE INDEX tasks_project_due_idx ON tasks (project_id, due_date, id) WHERE due_date IS NOT NULL;
CREATE INDEX tasks_assignee_idx ON tasks (assignee_id) WHERE assignee_id IS NOT NULL;
CREATE INDEX tasks_title_trgm_idx ON tasks USING gin (title gin_trgm_ops);

CREATE TABLE comments (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id    uuid        NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
    author_id  uuid        NOT NULL REFERENCES users (id),
    body       text        NOT NULL CHECK (length(btrim(body)) BETWEEN 1 AND 2000),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX comments_task_created_idx ON comments (task_id, created_at, id);

CREATE TABLE audit_log (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    actor_id    uuid,
    action      text        NOT NULL CHECK (action IN ('create', 'update', 'delete')),
    entity_type text        NOT NULL CHECK (entity_type IN ('team', 'member', 'project', 'task', 'comment')),
    entity_id   uuid        NOT NULL,
    details     jsonb       NOT NULL DEFAULT '{}'
);
CREATE INDEX audit_occurred_idx ON audit_log (occurred_at DESC, id DESC);
CREATE INDEX audit_entity_idx ON audit_log (entity_type, entity_id);
CREATE INDEX audit_actor_idx ON audit_log (actor_id) WHERE actor_id IS NOT NULL;

CREATE TABLE idempotency_keys (
    user_id       uuid        NOT NULL,
    key           text        NOT NULL CHECK (length(key) BETWEEN 8 AND 128),
    request_hash  text        NOT NULL,
    status_code   integer,
    response_body jsonb,
    created_at    timestamptz NOT NULL DEFAULT now(),
    expires_at    timestamptz NOT NULL DEFAULT now() + interval '24 hours',
    PRIMARY KEY (user_id, key)
);
CREATE INDEX idempotency_expires_idx ON idempotency_keys (expires_at);

-- Trigger functions ----------------------------------------------------------

-- Bumps `version` only when a column really changed, so a no-op PATCH keeps the same ETag.
CREATE FUNCTION bump_version() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW IS DISTINCT FROM OLD THEN
        NEW.version := OLD.version + 1;
    END IF;
    RETURN NEW;
END
$$;

CREATE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW IS DISTINCT FROM OLD THEN
        NEW.updated_at := now();
    END IF;
    RETURN NEW;
END
$$;

-- Keeps completed_at in step with status, so the CHECK on tasks always holds.
CREATE FUNCTION sync_completed_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'done' THEN
        IF TG_OP = 'UPDATE' AND OLD.status = 'done' THEN
            NEW.completed_at := OLD.completed_at;
        ELSE
            NEW.completed_at := now();
        END IF;
    ELSE
        NEW.completed_at := NULL;
    END IF;
    RETURN NEW;
END
$$;

-- The API sets app.current_user_id inside each write transaction (SELECT set_config(..., true)).
CREATE FUNCTION audit_row_change() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    entity   text := TG_ARGV[0];
    new_row  jsonb;
    old_row  jsonb;
    changed  jsonb;
    actor    uuid := nullif(current_setting('app.current_user_id', true), '')::uuid;
BEGIN
    IF TG_OP = 'INSERT' THEN
        new_row := to_jsonb(NEW);
        INSERT INTO audit_log (actor_id, action, entity_type, entity_id, details)
        VALUES (actor, 'create', entity, COALESCE((new_row->>'id'), new_row->>'user_id')::uuid, new_row);
    ELSIF TG_OP = 'UPDATE' THEN
        new_row := to_jsonb(NEW);
        old_row := to_jsonb(OLD);
        SELECT COALESCE(jsonb_object_agg(n.key, n.value), '{}')
          INTO changed
          FROM jsonb_each(new_row) AS n
          JOIN jsonb_each(old_row) AS o USING (key)
         WHERE n.value IS DISTINCT FROM o.value AND n.key NOT IN ('updated_at', 'version');
        IF changed <> '{}' THEN
            INSERT INTO audit_log (actor_id, action, entity_type, entity_id, details)
            VALUES (actor, 'update', entity, COALESCE((new_row->>'id'), new_row->>'user_id')::uuid, changed);
        END IF;
    ELSE
        old_row := to_jsonb(OLD);
        INSERT INTO audit_log (actor_id, action, entity_type, entity_id, details)
        VALUES (actor, 'delete', entity, COALESCE((old_row->>'id'), old_row->>'user_id')::uuid, old_row);
    END IF;
    RETURN NULL;
END
$$;

-- Triggers -------------------------------------------------------------------
-- BEFORE triggers of one event fire in name order: bump_version, set_updated_at, sync_completed_at.

CREATE TRIGGER trg_bump_version BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION bump_version();
CREATE TRIGGER trg_bump_version BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION bump_version();
CREATE TRIGGER trg_bump_version BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION bump_version();

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sync_completed_at BEFORE INSERT OR UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION sync_completed_at();

CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON teams
    FOR EACH ROW EXECUTE FUNCTION audit_row_change('team');
CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON team_members
    FOR EACH ROW EXECUTE FUNCTION audit_row_change('member');
CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON projects
    FOR EACH ROW EXECUTE FUNCTION audit_row_change('project');
CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON tasks
    FOR EACH ROW EXECUTE FUNCTION audit_row_change('task');
CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION audit_row_change('comment');

-- Stored functions: one atomic step each. Errors carry a custom SQLSTATE the API maps to a problem type:
-- TS404 not found (404), TS409 business rule (409), TS412 stale version (412), TS422 invalid input (422).

CREATE FUNCTION create_team(p_name text, p_description text, p_lead_id uuid, p_actor_id uuid)
RETURNS teams LANGUAGE plpgsql AS $$
DECLARE
    t teams;
BEGIN
    PERFORM set_config('app.current_user_id', p_actor_id::text, true);
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_lead_id) THEN
        RAISE EXCEPTION 'lead user % does not exist', p_lead_id USING ERRCODE = 'TS422';
    END IF;
    INSERT INTO teams (name, description, created_by)
    VALUES (p_name, COALESCE(p_description, ''), p_actor_id)
    RETURNING * INTO t;
    INSERT INTO team_members (team_id, user_id, role) VALUES (t.id, p_lead_id, 'lead');
    RETURN t;
END
$$;

CREATE FUNCTION complete_task(p_task_id uuid, p_actor_id uuid, p_expected_version integer DEFAULT NULL)
RETURNS tasks LANGUAGE plpgsql AS $$
DECLARE
    t tasks;
BEGIN
    SELECT * INTO t FROM tasks WHERE id = p_task_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'task % not found', p_task_id USING ERRCODE = 'TS404';
    END IF;
    IF p_expected_version IS NOT NULL AND t.version <> p_expected_version THEN
        RAISE EXCEPTION 'task changed (current version %)', t.version USING ERRCODE = 'TS412';
    END IF;
    IF t.status = 'cancelled' THEN
        RAISE EXCEPTION 'a cancelled task cannot be completed' USING ERRCODE = 'TS409';
    END IF;
    IF t.status = 'done' THEN
        RETURN t;
    END IF;
    PERFORM set_config('app.current_user_id', p_actor_id::text, true);
    UPDATE tasks SET status = 'done' WHERE id = p_task_id RETURNING * INTO t;
    RETURN t;
END
$$;

CREATE FUNCTION reassign_task(p_task_id uuid, p_assignee_id uuid, p_actor_id uuid, p_expected_version integer DEFAULT NULL)
RETURNS tasks LANGUAGE plpgsql AS $$
DECLARE
    t tasks;
BEGIN
    SELECT * INTO t FROM tasks WHERE id = p_task_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'task % not found', p_task_id USING ERRCODE = 'TS404';
    END IF;
    IF p_expected_version IS NOT NULL AND t.version <> p_expected_version THEN
        RAISE EXCEPTION 'task changed (current version %)', t.version USING ERRCODE = 'TS412';
    END IF;
    IF t.status IN ('done', 'cancelled') THEN
        RAISE EXCEPTION 'a % task cannot be reassigned', t.status USING ERRCODE = 'TS409';
    END IF;
    IF p_assignee_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM projects p
          JOIN team_members m ON m.team_id = p.team_id
         WHERE p.id = t.project_id AND m.user_id = p_assignee_id
    ) THEN
        RAISE EXCEPTION 'user % is not a member of the project team', p_assignee_id USING ERRCODE = 'TS422';
    END IF;
    PERFORM set_config('app.current_user_id', p_actor_id::text, true);
    UPDATE tasks SET assignee_id = p_assignee_id WHERE id = p_task_id RETURNING * INTO t;
    RETURN t;
END
$$;

CREATE FUNCTION purge_expired_idempotency_keys() RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
    removed integer;
BEGIN
    DELETE FROM idempotency_keys WHERE expires_at < now();
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END
$$;

-- Privileges: the app role can read and write rows, run the functions and append to the audit log,
-- but cannot change the schema and cannot edit or delete audit entries.

GRANT USAGE ON SCHEMA public TO tasks_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO tasks_app;
REVOKE UPDATE, DELETE ON audit_log FROM tasks_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO tasks_app;
