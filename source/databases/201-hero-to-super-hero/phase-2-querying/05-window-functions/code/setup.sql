DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.sales (
    sale_id bigint GENERATED ALWAYS AS IDENTITY,
    team text NOT NULL,
    rep text NOT NULL,
    sold_on date NOT NULL,
    amount integer NOT NULL,
    CONSTRAINT pk_sales PRIMARY KEY (sale_id),
    CONSTRAINT ck_sales_amount CHECK (amount > 0)
);
INSERT INTO app.sales (team, rep, sold_on, amount) VALUES
    ('North', 'Ava', DATE '2026-01-10', 100),
    ('North', 'Ben', DATE '2026-01-10', 100),
    ('North', 'Cora', DATE '2026-01-11', 60),
    ('South', 'Dan', DATE '2026-01-10', 80);
