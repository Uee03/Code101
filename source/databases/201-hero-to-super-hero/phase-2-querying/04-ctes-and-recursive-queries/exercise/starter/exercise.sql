\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
WITH RECURSIVE tree AS (
    -- TODO: anchor category 2, with depth 0; select category_id, title, depth.
    SELECT category_id, title, 0 AS depth FROM app.categories WHERE false
    UNION ALL
    -- TODO: join children to tree on parent_id = tree.category_id.
    SELECT c.category_id, c.title, t.depth + 1
    FROM app.categories AS c JOIN tree AS t ON false
) CYCLE category_id SET is_cycle USING path
SELECT title, depth FROM tree WHERE NOT is_cycle ORDER BY depth, category_id;
