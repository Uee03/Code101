-- Reference only (SQLite 3.37 or later, for STRICT tables). NOT run by this lesson.
-- The same tasks as lesson.sql; compare each statement with its PostgreSQL form.
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    email TEXT NOT NULL
) STRICT;
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers (customer_id),
    total_cents INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
) STRICT;
CREATE TABLE loose (n INTEGER);
INSERT INTO loose (n) VALUES ('abc');
SELECT n, typeof(n) FROM loose;
SELECT 'abc' = 'ABC' AS equals, 'abc' LIKE 'ABC' AS like_match;
WITH t(n) AS (VALUES (1), (2), (3), (4), (5))
SELECT n FROM t ORDER BY n LIMIT 2 OFFSET 1;
INSERT INTO customers (email) VALUES ('ada@example.com') RETURNING customer_id;
INSERT INTO orders (customer_id, total_cents) VALUES (1, 1250) RETURNING order_id;
