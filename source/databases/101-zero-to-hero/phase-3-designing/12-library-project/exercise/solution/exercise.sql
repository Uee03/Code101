\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/schema.sql
\ir /scripts/seed.sql
SELECT b.title, COUNT(l.loan_id) AS times_borrowed
FROM library.books AS b
LEFT JOIN library.loans AS l ON l.book_id = b.book_id
GROUP BY b.book_id, b.title ORDER BY b.title;
