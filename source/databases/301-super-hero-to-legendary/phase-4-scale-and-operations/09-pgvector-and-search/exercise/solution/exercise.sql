\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT string_agg(article_id::text, ',' ORDER BY embedding <=> '[0.1,0.9,0]', article_id) AS by_cosine
FROM app.articles;
