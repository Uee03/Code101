DROP SCHEMA IF EXISTS app CASCADE;
DROP PUBLICATION IF EXISTS pub_orders;
CREATE SCHEMA app;
CREATE FUNCTION app.attempt(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    v_rows bigint;
BEGIN
    EXECUTE p_sql;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN 'ok:' || v_rows;
EXCEPTION WHEN OTHERS THEN
    RETURN 'err:' || SQLSTATE;
END
$$;
CREATE TABLE app.orders (
    order_id integer NOT NULL,
    customer text NOT NULL,
    total_cents integer NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);
INSERT INTO app.orders (order_id, customer, total_cents) VALUES
    (1, 'ada', 1250),
    (2, 'bo', 830),
    (3, 'cy', 2000);
CREATE TABLE app.audit_events (
    event text NOT NULL
);
INSERT INTO app.audit_events (event) VALUES ('start');
