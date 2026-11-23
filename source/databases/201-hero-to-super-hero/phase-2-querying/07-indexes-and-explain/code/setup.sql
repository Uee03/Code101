DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.tasks (
    task_id bigint GENERATED ALWAYS AS IDENTITY,
    project_id bigint NOT NULL,
    title text NOT NULL,
    state text NOT NULL,
    due_on date NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT pk_tasks PRIMARY KEY (task_id),
    CONSTRAINT ck_tasks_state CHECK (state IN ('open', 'done'))
);
INSERT INTO app.tasks (project_id, title, state, due_on, metadata) VALUES
    (1, 'Pack', 'open', DATE '2026-01-12', '{"priority":"high"}'),
    (1, 'Invoice', 'done', DATE '2026-01-10', '{}'),
    (1, 'Ship', 'open', DATE '2026-01-13', '{"priority":"high"}'),
    (2, 'Restock', 'open', DATE '2026-01-11', '{"priority":"low"}');
CREATE INDEX ix_tasks_project_due ON app.tasks (project_id, due_on, task_id) INCLUDE (title);
CREATE INDEX ix_tasks_open_due ON app.tasks (project_id, due_on, task_id)
    INCLUDE (title) WHERE state = 'open';
CREATE INDEX ix_tasks_metadata ON app.tasks USING gin (metadata);
ANALYZE app.tasks;
