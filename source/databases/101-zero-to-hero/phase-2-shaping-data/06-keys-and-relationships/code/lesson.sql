\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
SELECT member_id, name FROM practice.members ORDER BY member_id;
SELECT loan_id, member_id, title FROM practice.loans ORDER BY loan_id;
