CREATE TABLE orders (
    id integer PRIMARY KEY,
    customer text NOT NULL,
    total_cents integer NOT NULL CHECK (total_cents >= 0)
);

INSERT INTO orders (id, customer, total_cents) VALUES
    (1, 'Ada', 1250),
    (2, 'Grace', 4200),
    (3, 'Linus', 999),
    (4, 'Margaret', 15000),
    (5, 'Dennis', 300);
