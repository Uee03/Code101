\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
SELECT title, price FROM practice.books;
