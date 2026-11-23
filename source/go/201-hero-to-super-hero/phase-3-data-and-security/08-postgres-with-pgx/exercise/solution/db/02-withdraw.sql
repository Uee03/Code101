CREATE FUNCTION app.withdraw(p_account_id integer, p_amount_cents bigint)
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
       SET balance_cents = balance_cents - p_amount_cents
     WHERE id = p_account_id
    RETURNING balance_cents INTO new_balance;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'account % not found', p_account_id USING ERRCODE = 'P0002';
    END IF;

    RETURN new_balance;
END;
$$;
