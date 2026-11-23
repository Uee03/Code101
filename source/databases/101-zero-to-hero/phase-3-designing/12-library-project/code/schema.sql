DROP SCHEMA IF EXISTS library CASCADE;
CREATE SCHEMA library;
CREATE TABLE library.members (
    member_id bigint GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    email text NOT NULL,
    CONSTRAINT pk_members PRIMARY KEY (member_id),
    CONSTRAINT uq_members_email UNIQUE (email)
);
CREATE TABLE library.books (
    book_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_title UNIQUE (title)
);
CREATE TABLE library.loans (
    loan_id bigint GENERATED ALWAYS AS IDENTITY,
    member_id bigint NOT NULL,
    book_id bigint NOT NULL,
    borrowed_on date NOT NULL DEFAULT CURRENT_DATE,
    due_on date NOT NULL,
    returned_on date,
    CONSTRAINT pk_loans PRIMARY KEY (loan_id),
    CONSTRAINT fk_loans_members FOREIGN KEY (member_id)
        REFERENCES library.members (member_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_loans_books FOREIGN KEY (book_id)
        REFERENCES library.books (book_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_loans_due CHECK (due_on >= borrowed_on),
    CONSTRAINT ck_loans_returned CHECK (returned_on >= borrowed_on)
);
