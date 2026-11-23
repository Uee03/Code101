DROP SCHEMA IF EXISTS library CASCADE;
CREATE SCHEMA library;
CREATE TABLE library.members (
    member_id bigint GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    email text NOT NULL,
    joined_on date NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_members PRIMARY KEY (member_id),
    CONSTRAINT uq_members_email UNIQUE (email)
);
CREATE TABLE library.books (
    book_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    stock integer NOT NULL DEFAULT 0,
    price numeric(10,2) NOT NULL,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_title UNIQUE (title),
    CONSTRAINT ck_books_stock CHECK (stock >= 0),
    CONSTRAINT ck_books_price CHECK (price >= 0)
);
INSERT INTO library.members (name, email)
VALUES ('Ava', 'ava@example.test'), ('Ben', 'ben@example.test');
INSERT INTO library.books (title, stock, price)
VALUES ('Field Notes', 3, 12.50), ('City Maps', 2, 8.00);
