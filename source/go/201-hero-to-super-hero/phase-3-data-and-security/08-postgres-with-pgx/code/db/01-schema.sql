-- Runs once, when the database volume is created empty (files run in name order).
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.accounts (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner         text    NOT NULL,
    balance_cents bigint  NOT NULL DEFAULT 0,
    CONSTRAINT owner_unique UNIQUE (owner),
    CONSTRAINT owner_length CHECK (length(owner) BETWEEN 1 AND 100),
    CONSTRAINT balance_non_negative CHECK (balance_cents >= 0)
);

-- A stored function: the rule "amount must be positive" and the update live in the database.
CREATE FUNCTION app.deposit(p_account_id integer, p_amount_cents bigint)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    new_balance bigint;
BEGIN
    IF p_amount_cents <= 0 THEN
        RAISE EXCEPTION 'amount must be positive' USING ERRCODE = '22023';
    END IF;

    UPDATE app.accounts
       SET balance_cents = balance_cents + p_amount_cents
     WHERE id = p_account_id
    RETURNING balance_cents INTO new_balance;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'account % not found', p_account_id USING ERRCODE = 'P0002';
    END IF;

    RETURN new_balance;
END;
$$;
