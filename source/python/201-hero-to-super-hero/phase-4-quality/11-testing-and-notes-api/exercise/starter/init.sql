CREATE TABLE notes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title varchar(120) NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 120),
    owner varchar(200) NOT NULL
);
CREATE INDEX ix_notes_owner ON notes (owner);
