\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
SELECT title, price FROM practice.books
WHERE price >= 12 AND title LIKE 'F%'
ORDER BY price DESC, book_id
LIMIT 2;
