INSERT INTO library.members (name, email)
VALUES ('Ava', 'ava@example.test'), ('Ben', 'ben@example.test'),
       ('Cora', 'cora@example.test');
INSERT INTO library.books (title)
VALUES ('Field Notes'), ('Quiet Rivers'), ('City Maps'), ('Forest Walks');
INSERT INTO library.loans (member_id, book_id, borrowed_on, due_on, returned_on)
VALUES (1, 1, '2026-11-01', '2026-12-01', NULL),
       (1, 2, '2026-11-01', '2026-12-01', '2026-11-18'),
       (2, 3, '2026-11-05', '2026-12-05', NULL);
