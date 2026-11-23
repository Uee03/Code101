\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
CREATE INDEX ix_books_price ON practice.books (price);
ANALYZE practice.books;
EXPLAIN (COSTS OFF)
SELECT title FROM practice.books WHERE price < 15;
