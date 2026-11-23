DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE DOMAIN app.nonnegative_amount AS numeric(10,2)
    CONSTRAINT ck_nonnegative_amount CHECK (VALUE >= 0);
CREATE TYPE app.order_state AS ENUM ('draft', 'paid', 'shipped');
CREATE TYPE app.price_quote AS (sku text, amount numeric(10,2));
CREATE TABLE app.products (
    product_id bigint GENERATED ALWAYS AS IDENTITY,
    sku text NOT NULL,
    price app.nonnegative_amount NOT NULL,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku)
);
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    product_id bigint NOT NULL,
    state app.order_state NOT NULL DEFAULT 'draft',
    quantity integer NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_products FOREIGN KEY (product_id)
        REFERENCES app.products (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_orders_quantity CHECK (quantity > 0),
    CONSTRAINT ck_orders_dates CHECK (ends_on >= starts_on)
);
CREATE INDEX ix_orders_product_id ON app.orders (product_id);
INSERT INTO app.products (sku, price) VALUES ('N1', 5.00), ('P1', 2.00);
INSERT INTO app.orders (product_id, quantity, starts_on, ends_on)
VALUES (1, 2, DATE '2026-01-10', DATE '2026-01-11');
