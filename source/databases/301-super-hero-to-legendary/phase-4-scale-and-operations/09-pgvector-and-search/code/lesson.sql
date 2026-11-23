\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT article_id,
       round((embedding <-> '[1,0,0]')::numeric, 3) AS l2,
       round((embedding <=> '[1,0,0]')::numeric, 3) AS cosine
FROM app.articles
ORDER BY embedding <-> '[1,0,0]', article_id;
SELECT string_agg(article_id::text, ',' ORDER BY d, article_id) AS nearest_two
FROM (SELECT article_id, embedding <-> '[1,0,0]' AS d FROM app.articles ORDER BY d, article_id LIMIT 2) AS t;
SELECT vector_dims(embedding) AS dims, 4 * 1536 + 8 AS bytes_for_1536_dims
FROM app.articles WHERE article_id = 1;
SELECT app.attempt('INSERT INTO app.articles (article_id, title, body, embedding) VALUES (9, ''x'', ''y'', ''[1,2]'')') AS wrong_dimension;
SELECT q, (SELECT string_agg(article_id::text, ',' ORDER BY article_id)
           FROM app.articles WHERE search @@ websearch_to_tsquery('english', q)) AS matches
FROM (VALUES ('search'), ('dead rows'), ('indexing'), ('the log'), ('missing')) AS t(q)
ORDER BY q;
SELECT article_id FROM app.articles
WHERE search @@ websearch_to_tsquery('english', 'index OR log')
ORDER BY embedding <-> '[1,0,0]', article_id;
