\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
INSERT INTO practice.loans (member_id, title)
VALUES (2, 'Forest Walks') RETURNING loan_id, member_id, title;
