DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    state text NOT NULL DEFAULT 'draft',
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT ck_orders_state CHECK (state IN ('draft', 'paid'))
);
CREATE TABLE app.markers (
    marker_id bigint GENERATED ALWAYS AS IDENTITY,
    note text NOT NULL,
    CONSTRAINT pk_markers PRIMARY KEY (marker_id)
);
CREATE TABLE app.error_checks (
    code text,
    CONSTRAINT pk_error_checks PRIMARY KEY (code)
);
INSERT INTO app.orders DEFAULT VALUES;
CREATE FUNCTION app.line_total(p_quantity integer, p_unit_price numeric)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE STRICT SECURITY INVOKER AS $$
BEGIN
    IF p_quantity <= 0 OR p_unit_price < 0 THEN
        RAISE EXCEPTION 'quantity must be positive and price nonnegative'
            USING ERRCODE = 'P2011';
    END IF;
    RETURN p_quantity * p_unit_price;
END;
$$;
CREATE PROCEDURE app.pay_order(p_order_id bigint)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    UPDATE app.orders SET state = 'paid'
    WHERE order_id = p_order_id AND state = 'draft';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'order missing or not draft' USING ERRCODE = 'P2012';
    END IF;
END;
$$;
CREATE PROCEDURE app.commit_markers(p_note text)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    INSERT INTO app.markers (note) VALUES (p_note || ':first');
    COMMIT;
    INSERT INTO app.markers (note) VALUES (p_note || ':second');
    COMMIT;
END;
$$;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA app FROM PUBLIC;
REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA app FROM PUBLIC;
