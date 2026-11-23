\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
SELECT m.name, l.title
FROM practice.members AS m
INNER JOIN practice.loans AS l ON l.member_id = m.member_id
ORDER BY m.member_id, l.loan_id;
SELECT m.name, l.title
FROM practice.members AS m
LEFT JOIN practice.loans AS l ON l.member_id = m.member_id
ORDER BY m.member_id, l.loan_id;
