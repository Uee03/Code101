SELECT m.name, b.title, l.due_on
FROM library.loans AS l
INNER JOIN library.members AS m ON m.member_id = l.member_id
INNER JOIN library.books AS b ON b.book_id = l.book_id
WHERE l.returned_on IS NULL
ORDER BY m.name, b.title;
SELECT m.name, COUNT(l.loan_id) AS active_loans
FROM library.members AS m
LEFT JOIN library.loans AS l
    ON l.member_id = m.member_id AND l.returned_on IS NULL
GROUP BY m.member_id, m.name
ORDER BY m.name;
