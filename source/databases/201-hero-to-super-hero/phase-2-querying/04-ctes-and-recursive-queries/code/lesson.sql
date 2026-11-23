\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
WITH child_counts AS (
    SELECT parent_id, COUNT(*) AS direct_children
    FROM app.categories
    WHERE parent_id IS NOT NULL
    GROUP BY parent_id
)
SELECT c.title, cc.direct_children
FROM child_counts AS cc
JOIN app.categories AS c ON c.category_id = cc.parent_id
ORDER BY c.category_id;
WITH RECURSIVE tree AS (
    SELECT category_id, parent_id, title, 0 AS depth
    FROM app.categories WHERE category_id = 1
    UNION ALL
    SELECT c.category_id, c.parent_id, c.title, t.depth + 1
    FROM app.categories AS c
    JOIN tree AS t ON c.parent_id = t.category_id
) CYCLE category_id SET is_cycle USING path
SELECT category_id, title, depth FROM tree
WHERE NOT is_cycle
ORDER BY depth, category_id;
