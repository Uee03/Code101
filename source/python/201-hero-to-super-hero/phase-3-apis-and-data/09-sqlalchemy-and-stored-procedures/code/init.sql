CREATE TABLE notes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title varchar(120) NOT NULL CHECK (char_length(btrim(title)) > 0)
);

CREATE PROCEDURE add_note(p_title text)
LANGUAGE SQL
AS $$
    INSERT INTO notes (title) VALUES (p_title);
$$;
