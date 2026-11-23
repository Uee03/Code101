\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
ANALYZE practice.books;
EXPLAIN (COSTS OFF)
SELECT book_id, title FROM practice.books WHERE title = 'City Maps';
CREATE INDEX ix_books_title ON practice.books (title);
ANALYZE practice.books;
EXPLAIN (COSTS OFF)
SELECT book_id, title FROM practice.books WHERE title = 'City Maps';
