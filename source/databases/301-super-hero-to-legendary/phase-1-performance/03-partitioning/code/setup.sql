DROP SCHEMA IF EXISTS app CASCADE;
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
CREATE FUNCTION app.partitions_in_plan(p_query text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_line text;
    v_match text[];
    v_found text[] := '{}';
BEGIN
    FOR v_line IN EXECUTE 'EXPLAIN (COSTS OFF) ' || p_query LOOP
        FOR v_match IN SELECT regexp_matches(v_line, 'measurements_[0-9]{4}_[0-9]{2}', 'g') LOOP
            IF NOT (v_match[1] = ANY (v_found)) THEN
                v_found := v_found || v_match[1];
            END IF;
        END LOOP;
    END LOOP;
    RETURN cardinality(v_found);
END
$$;
CREATE TABLE app.measurements (
    measurement_id bigint NOT NULL,
    device_id integer NOT NULL,
    recorded_on date NOT NULL,
    reading numeric(5,1) NOT NULL,
    CONSTRAINT pk_measurements PRIMARY KEY (measurement_id, recorded_on)
) PARTITION BY RANGE (recorded_on);
CREATE TABLE app.measurements_2026_01 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE app.measurements_2026_02 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE app.measurements_2026_03 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES
    (1, 1, DATE '2026-01-05', 10.5),
    (2, 1, DATE '2026-01-20', 11.0),
    (3, 2, DATE '2026-02-03', 9.5),
    (4, 2, DATE '2026-02-14', 9.0),
    (5, 3, DATE '2026-03-01', 12.0),
    (6, 3, DATE '2026-03-31', 12.5);
CREATE TABLE app.sales (
    sale_id integer NOT NULL,
    region text NOT NULL,
    amount integer NOT NULL,
    CONSTRAINT pk_sales PRIMARY KEY (sale_id, region)
) PARTITION BY LIST (region);
CREATE TABLE app.sales_eu PARTITION OF app.sales FOR VALUES IN ('eu');
CREATE TABLE app.sales_us PARTITION OF app.sales FOR VALUES IN ('us');
CREATE TABLE app.sales_other PARTITION OF app.sales DEFAULT;
INSERT INTO app.sales (sale_id, region, amount) VALUES
    (1, 'eu', 10), (2, 'eu', 20), (3, 'us', 30), (4, 'apac', 40);
CREATE TABLE app.sessions (
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT pk_sessions PRIMARY KEY (session_id, user_id)
) PARTITION BY HASH (user_id);
CREATE TABLE app.sessions_p0 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE app.sessions_p1 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE app.sessions_p2 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE app.sessions_p3 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
INSERT INTO app.sessions (session_id, user_id) SELECT n, n FROM generate_series(1, 8) AS n;
ANALYZE app.measurements;
