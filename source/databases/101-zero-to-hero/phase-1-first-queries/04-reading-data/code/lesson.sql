\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
SELECT title, price FROM practice.books
WHERE available = true AND price <= 15
ORDER BY price, book_id
LIMIT 2;
SELECT title FROM practice.books WHERE title LIKE 'F%' ORDER BY title;
SELECT title FROM practice.books WHERE published_on IS NULL ORDER BY title;
