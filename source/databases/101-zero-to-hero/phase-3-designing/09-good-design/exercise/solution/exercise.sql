\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
INSERT INTO library.books (title, price)
VALUES ('Forest Walks', 15.00) RETURNING title, stock, price;
