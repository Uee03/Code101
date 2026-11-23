DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.sales (
    sale_id bigint GENERATED ALWAYS AS IDENTITY,
    team text NOT NULL,
    amount numeric(10,2) NOT NULL,
    CONSTRAINT pk_sales PRIMARY KEY (sale_id),
    CONSTRAINT ck_sales_amount CHECK (amount >= 0)
);
INSERT INTO app.sales (team, amount) VALUES ('North', 10.00), ('North', 20.00), ('South', 5.00);
CREATE VIEW app.team_totals WITH (security_invoker = true) AS
SELECT team, SUM(amount)::numeric(10,2) AS total FROM app.sales GROUP BY team;
CREATE MATERIALIZED VIEW app.cached_team_totals AS
SELECT team, total FROM app.team_totals;
CREATE UNIQUE INDEX uq_cached_team_totals_team ON app.cached_team_totals (team);
