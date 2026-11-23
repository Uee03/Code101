-- Solution for the three exercise queries. Run it with:
--   Windows PowerShell: Get-Content my-queries.sql | docker compose exec -T db psql -U search -d searchdb
--   macOS/Linux: docker compose exec -T db psql -U search -d searchdb < my-queries.sql

SELECT count(*) AS chunks FROM search.chunks;

SELECT embedding_model, count(*) AS chunks, vector_dims(embedding) AS dimensions
FROM search.chunks
GROUP BY embedding_model, vector_dims(embedding);

SELECT b.section AS title, (a.embedding <#> b.embedding) AS negative_inner_product
FROM search.chunks AS a
JOIN search.chunks AS b ON a.id <> b.id
WHERE a.section = 'Returns'
ORDER BY a.embedding <#> b.embedding
LIMIT 3;
