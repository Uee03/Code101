DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.events (
    event_id integer NOT NULL,
    status text NOT NULL,
    zone integer NOT NULL,
    region integer NOT NULL,
    payload text NOT NULL,
    CONSTRAINT pk_events PRIMARY KEY (event_id)
) WITH (autovacuum_enabled = false);
INSERT INTO app.events (event_id, status, zone, region, payload)
SELECT n,
       CASE WHEN n % 4 = 0 THEN 'done' ELSE 'open' END,
       n % 10,
       (n % 10) / 5,
       repeat('x', 100)
FROM generate_series(1, 1000) AS n;
CREATE FUNCTION app.estimated_rows(p_query text) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE
    v_plan json;
BEGIN
    EXECUTE 'EXPLAIN (FORMAT JSON) ' || p_query INTO v_plan;
    RETURN (v_plan -> 0 -> 'Plan' ->> 'Plan Rows')::bigint;
END
$$;
