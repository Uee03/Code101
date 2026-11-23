DROP SCHEMA IF EXISTS practice CASCADE;
CREATE SCHEMA practice;
CREATE TABLE practice.members (
    member_id bigint GENERATED ALWAYS AS IDENTITY,
    name text,
    CONSTRAINT pk_members PRIMARY KEY (member_id)
);
CREATE TABLE practice.loans (
    loan_id bigint GENERATED ALWAYS AS IDENTITY,
    member_id bigint,
    title text,
    CONSTRAINT pk_loans PRIMARY KEY (loan_id),
    CONSTRAINT fk_loans_members FOREIGN KEY (member_id)
        REFERENCES practice.members (member_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
);
INSERT INTO practice.members (name) VALUES ('Ava'), ('Ben'), ('Cora');
INSERT INTO practice.loans (member_id, title)
VALUES (1, 'Field Notes'), (1, 'Quiet Rivers'), (2, 'City Maps');
