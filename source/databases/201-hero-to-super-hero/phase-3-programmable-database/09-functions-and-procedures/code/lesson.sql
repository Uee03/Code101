\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
BEGIN;
SELECT app.line_total(2, 5.00)::numeric(10,2) AS total;
CALL app.pay_order(1);
SELECT state AS inside_transaction FROM app.orders WHERE order_id = 1;
ROLLBACK;
SELECT state AS after_rollback FROM app.orders WHERE order_id = 1;
DO $$
BEGIN
    BEGIN
        PERFORM app.line_total(0, 5.00);
        RAISE EXCEPTION 'expected P2011';
    EXCEPTION WHEN SQLSTATE 'P2011' THEN
        INSERT INTO app.error_checks (code) VALUES ('P2011');
    END;
    BEGIN
        CALL app.pay_order(999);
        RAISE EXCEPTION 'expected P2012';
    EXCEPTION WHEN SQLSTATE 'P2012' THEN
        INSERT INTO app.error_checks (code) VALUES ('P2012');
    END;
END;
$$;
SELECT code AS caught_sqlstate FROM app.error_checks ORDER BY code;
CALL app.commit_markers('demo');
SELECT note FROM app.markers ORDER BY marker_id;
