\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE FUNCTION app.discounted(p_amount numeric, p_percent integer)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE STRICT SECURITY INVOKER AS $$
BEGIN
    -- TODO: reject negative amount or percent outside 0..100 with SQLSTATE P2013.
    -- TODO: return amount * (100 - percent) / 100.
    RETURN p_amount;
END;
$$;
REVOKE EXECUTE ON FUNCTION app.discounted(numeric, integer) FROM PUBLIC;
SELECT app.discounted(100.00, 10)::numeric(10,2) AS discounted;
