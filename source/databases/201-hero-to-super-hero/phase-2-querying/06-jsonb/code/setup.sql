DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.products (
    product_id bigint GENERATED ALWAYS AS IDENTITY,
    sku text NOT NULL,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT ck_products_attributes_object CHECK (jsonb_typeof(attributes) = 'object')
);
INSERT INTO app.products (sku, attributes) VALUES
    ('N1', '{"color":"blue","pages":80,"tags":["paper","gift"]}'),
    ('N2', '{"color":"red","pages":40,"gift_note":null}'),
    ('P1', '{"ink":"blue","tags":["writing"]}');
CREATE INDEX ix_products_attributes ON app.products USING gin (attributes);
CREATE INDEX ix_products_color ON app.products ((attributes ->> 'color'));
