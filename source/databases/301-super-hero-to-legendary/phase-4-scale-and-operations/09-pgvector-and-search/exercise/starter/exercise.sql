\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: order the article ids from nearest to farthest by COSINE distance (operator <=>)
-- to the query vector '[0.1,0.9,0]'. Break ties by article_id.
SELECT string_agg(article_id::text, ',' ORDER BY article_id) AS by_cosine FROM app.articles;
