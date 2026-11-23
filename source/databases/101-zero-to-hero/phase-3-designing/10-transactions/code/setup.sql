DROP SCHEMA IF EXISTS bank CASCADE;
CREATE SCHEMA bank;
CREATE TABLE bank.accounts (
    account_id bigint GENERATED ALWAYS AS IDENTITY,
    owner text NOT NULL,
    balance numeric(12,2) NOT NULL,
    CONSTRAINT pk_accounts PRIMARY KEY (account_id),
    CONSTRAINT ck_accounts_balance CHECK (balance >= 0)
);
INSERT INTO bank.accounts (owner, balance) VALUES ('Ava', 100.00), ('Ben', 50.00);
