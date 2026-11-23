\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
SELECT m.name, l.title
FROM practice.members AS m
LEFT JOIN practice.loans AS l ON l.member_id = m.member_id
WHERE l.loan_id IS NULL ORDER BY m.name;
