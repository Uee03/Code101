DROP SCHEMA IF EXISTS practice CASCADE;
CREATE SCHEMA practice;
CREATE TABLE practice.sales (
    sale_id bigint GENERATED ALWAYS AS IDENTITY,
    category text,
    quantity integer,
    unit_price numeric(10,2),
    CONSTRAINT pk_sales PRIMARY KEY (sale_id)
);
INSERT INTO practice.sales (category, quantity, unit_price)
VALUES ('stationery', 2, 3.00), ('stationery', 1, 5.00),
       ('books', 2, 10.00), ('books', 1, 15.00), ('games', 1, 12.00);
