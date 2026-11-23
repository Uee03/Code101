CREATE TABLE notes (
    id SERIAL PRIMARY KEY,
    body TEXT NOT NULL
);

INSERT INTO notes (body) VALUES
    ('first note'),
    ('second note'),
    ('third note');
