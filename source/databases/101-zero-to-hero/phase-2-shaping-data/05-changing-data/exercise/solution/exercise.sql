\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
UPDATE practice.books SET available = false
WHERE book_id = 3 RETURNING book_id, title, available;
DELETE FROM practice.books WHERE book_id = 4 RETURNING book_id, title;
