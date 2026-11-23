DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.tasks (
    task_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tasks PRIMARY KEY (task_id)
);
CREATE TABLE app.task_audit (
    audit_id bigint GENERATED ALWAYS AS IDENTITY,
    task_id bigint NOT NULL,
    old_title text NOT NULL,
    new_title text NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by text NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_task_audit PRIMARY KEY (audit_id)
);
INSERT INTO app.tasks (title, updated_at) VALUES ('Pack', TIMESTAMPTZ '2000-01-01 00:00:00+00');
CREATE FUNCTION app.touch_task() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;
CREATE FUNCTION app.audit_task_title() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    INSERT INTO app.task_audit (task_id, old_title, new_title)
    VALUES (OLD.task_id, OLD.title, NEW.title);
    RETURN NULL;
END;
$$;
CREATE TRIGGER tr_tasks_touch BEFORE UPDATE ON app.tasks
FOR EACH ROW WHEN (OLD.title IS DISTINCT FROM NEW.title)
EXECUTE FUNCTION app.touch_task();
CREATE TRIGGER tr_tasks_audit AFTER UPDATE ON app.tasks
FOR EACH ROW WHEN (OLD.title IS DISTINCT FROM NEW.title)
EXECUTE FUNCTION app.audit_task_title();
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA app FROM PUBLIC;
REVOKE ALL ON app.task_audit FROM PUBLIC;
