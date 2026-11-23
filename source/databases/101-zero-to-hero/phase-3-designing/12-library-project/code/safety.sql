PREPARE member_loans(bigint) AS
SELECT loan_id, book_id FROM library.loans
WHERE member_id = $1 ORDER BY loan_id;
EXECUTE member_loans(1);
DEALLOCATE member_loans;
CREATE ROLE library_reader NOLOGIN;
GRANT CONNECT ON DATABASE code101 TO library_reader;
GRANT USAGE ON SCHEMA library TO library_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA library TO library_reader;
SET ROLE library_reader;
SELECT current_user AS reading_as;
RESET ROLE;
