\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
UPDATE practice.books SET price = price + 1
WHERE book_id = 1 RETURNING book_id, title, price;
DELETE FROM practice.books WHERE book_id = 2 RETURNING book_id, title;
SELECT book_id, title, price FROM practice.books ORDER BY book_id;
