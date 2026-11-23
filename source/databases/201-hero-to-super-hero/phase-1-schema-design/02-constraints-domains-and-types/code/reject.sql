\set ON_ERROR_STOP on
INSERT INTO app.products (sku, price) VALUES ('BAD', -1.00);
