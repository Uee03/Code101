-- Exercise: for every user, count the tasks assigned to them that are still open
-- (status is not done and not cancelled). Users with no open task must show 0.
SELECT u.username,
       count(t.id) FILTER (WHERE t.status NOT IN ('done', 'cancelled')) AS open_tasks
FROM users u
LEFT JOIN tasks t ON t.assignee_id = u.id
GROUP BY u.username
ORDER BY u.username;
