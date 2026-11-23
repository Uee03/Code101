\set ON_ERROR_STOP on
\pset null '(none)'
SELECT current_database() AS database, current_user AS username;
SELECT 'Connection works' AS message;
