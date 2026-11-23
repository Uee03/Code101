\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
INSERT INTO library.members (name, email)
VALUES ('Cora', 'cora@example.test') RETURNING name, email;
INSERT INTO library.books (title, price)
VALUES ('Trail Guide', 9.00) RETURNING title, stock;
SELECT name, email FROM library.members ORDER BY member_id;
