ALTER TABLE app.tasks ADD COLUMN priority integer NOT NULL DEFAULT 1;
ALTER TABLE app.tasks ADD CONSTRAINT ck_tasks_priority CHECK (priority BETWEEN 1 AND 3);
