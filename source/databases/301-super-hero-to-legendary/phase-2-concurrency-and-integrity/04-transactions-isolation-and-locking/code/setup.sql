DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.accounts (
    account_id integer NOT NULL,
    owner text NOT NULL,
    balance numeric(10,2) NOT NULL,
    CONSTRAINT pk_accounts PRIMARY KEY (account_id),
    CONSTRAINT ck_accounts_balance CHECK (balance >= 0)
);
INSERT INTO app.accounts (account_id, owner, balance) VALUES (1, 'Ada', 100.00), (2, 'Bo', 100.00);
CREATE TABLE app.jobs (
    job_id integer NOT NULL,
    state text NOT NULL,
    CONSTRAINT pk_jobs PRIMARY KEY (job_id),
    CONSTRAINT ck_jobs_state CHECK (state IN ('pending', 'running'))
);
INSERT INTO app.jobs (job_id, state) VALUES (1, 'pending'), (2, 'pending'), (3, 'pending');
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
CREATE FUNCTION app.transfer(p_from integer, p_to integer, p_amount numeric) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM 1 FROM app.accounts WHERE account_id IN (p_from, p_to) ORDER BY account_id FOR UPDATE;
    UPDATE app.accounts SET balance = balance - p_amount WHERE account_id = p_from;
    UPDATE app.accounts SET balance = balance + p_amount WHERE account_id = p_to;
END
$$;
