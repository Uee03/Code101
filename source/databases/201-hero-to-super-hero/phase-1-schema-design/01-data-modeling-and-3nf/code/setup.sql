DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.customers (
    customer_id bigint GENERATED ALWAYS AS IDENTITY,
    email text NOT NULL,
    name text NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email)
);
CREATE TABLE app.products (
    product_id bigint GENERATED ALWAYS AS IDENTITY,
    sku text NOT NULL,
    title text NOT NULL,
    current_price numeric(10,2) NOT NULL,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT ck_products_price CHECK (current_price >= 0)
);
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    customer_id bigint NOT NULL,
    placed_on date NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id)
        REFERENCES app.customers (customer_id) ON DELETE RESTRICT
);
CREATE TABLE app.order_items (
    order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id),
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id)
        REFERENCES app.orders (order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_order_items_products FOREIGN KEY (product_id)
        REFERENCES app.products (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT ck_order_items_price CHECK (unit_price >= 0)
);
CREATE INDEX ix_orders_customer_id ON app.orders (customer_id);
CREATE INDEX ix_order_items_product_id ON app.order_items (product_id);
INSERT INTO app.customers (email, name)
VALUES ('ava@example.test', 'Ava'), ('ben@example.test', 'Ben');
INSERT INTO app.products (sku, title, current_price)
VALUES ('N1', 'Notebook', 5.00), ('P1', 'Pen', 2.00);
INSERT INTO app.orders (customer_id, placed_on)
VALUES (1, DATE '2026-01-10'), (1, DATE '2026-01-11'), (2, DATE '2026-01-11');
INSERT INTO app.order_items (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 2, 5.00), (1, 2, 1, 2.00), (2, 2, 3, 2.00), (3, 1, 1, 5.00);
