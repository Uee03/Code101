DROP SCHEMA IF EXISTS practice CASCADE;
CREATE SCHEMA practice;
CREATE TABLE practice.books (
    book_id integer,
    title text,
    price numeric(10,2),
    available boolean,
    published_on date
);
INSERT INTO practice.books (book_id, title, price, available, published_on)
VALUES
    (1, 'Field Notes', 12.50, true, '2024-01-15'),
    (2, 'Quiet Rivers', 20.00, false, NULL),
    (3, 'City Maps', 8.00, true, '2023-06-01'),
    (4, 'Forest Walks', 15.00, true, '2025-03-10');
