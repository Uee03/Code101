\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE FUNCTION app.discounted(p_amount numeric, p_percent integer)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE STRICT SECURITY INVOKER AS $$
BEGIN
    IF p_amount < 0 OR p_percent < 0 OR p_percent > 100 THEN
        RAISE EXCEPTION 'invalid discount input' USING ERRCODE = 'P2013';
    END IF;
    RETURN p_amount * (100 - p_percent) / 100;
END;
$$;
REVOKE EXECUTE ON FUNCTION app.discounted(numeric, integer) FROM PUBLIC;
SELECT app.discounted(100.00, 10)::numeric(10,2) AS discounted;
