\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
WITH RECURSIVE tree AS (
    SELECT category_id, title, 0 AS depth FROM app.categories WHERE category_id = 2
    UNION ALL
    SELECT c.category_id, c.title, t.depth + 1
    FROM app.categories AS c JOIN tree AS t ON c.parent_id = t.category_id
) CYCLE category_id SET is_cycle USING path
SELECT title, depth FROM tree WHERE NOT is_cycle ORDER BY depth, category_id;
