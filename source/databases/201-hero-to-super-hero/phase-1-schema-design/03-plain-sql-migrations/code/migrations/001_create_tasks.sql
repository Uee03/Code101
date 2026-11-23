CREATE TABLE app.tasks (
    task_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    CONSTRAINT pk_tasks PRIMARY KEY (task_id)
);
INSERT INTO app.tasks (title) VALUES ('Pack order');
