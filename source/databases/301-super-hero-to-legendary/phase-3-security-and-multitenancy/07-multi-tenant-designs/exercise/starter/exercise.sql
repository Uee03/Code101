\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE TABLE app.comments (
    tenant_id integer NOT NULL,
    comment_id integer NOT NULL,
    task_id integer NOT NULL,
    body text NOT NULL,
    CONSTRAINT pk_comments PRIMARY KEY (tenant_id, comment_id)
    -- TODO: add a composite foreign key named fk_comments_task on (tenant_id, task_id)
    -- referencing app.tasks (tenant_id, task_id). Remember the comma after the primary key line.
);
SELECT app.attempt('INSERT INTO app.comments (tenant_id, comment_id, task_id, body) VALUES (1, 1, 1, ''fine'')') AS own_tenant_comment,
       app.attempt('INSERT INTO app.comments (tenant_id, comment_id, task_id, body) VALUES (2, 2, 2, ''cross'')') AS cross_tenant_comment;
