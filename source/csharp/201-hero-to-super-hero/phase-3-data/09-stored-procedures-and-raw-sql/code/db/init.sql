CREATE TABLE notes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title text NOT NULL,
    archived boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO notes (title, created_at) VALUES
    ('Buy milk', now() - interval '40 days'),
    ('Call Ada', now() - interval '10 days'),
    ('Milk run plan', now() - interval '1 day'),
    ('Write report', now());

CREATE FUNCTION search_notes(term text)
RETURNS TABLE (id integer, title text, archived boolean)
LANGUAGE sql STABLE
AS $$
    SELECT n.id, n.title, n.archived
    FROM notes n
    WHERE n.title ILIKE '%' || term || '%'
    ORDER BY n.id;
$$;

CREATE PROCEDURE archive_notes_older_than(older_than_days integer)
LANGUAGE sql
AS $$
    UPDATE notes
    SET archived = true
    WHERE archived = false
      AND created_at < now() - make_interval(days => older_than_days);
$$;
