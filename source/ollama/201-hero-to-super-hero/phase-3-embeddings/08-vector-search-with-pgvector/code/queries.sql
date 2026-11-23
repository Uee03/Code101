-- 1. The notes closest to the stored note "Opening hours" (exact scan, no query vector needed)
SELECT b.section, round((a.embedding <=> b.embedding)::numeric, 4) AS distance
FROM search.chunks AS a
JOIN search.chunks AS b ON a.id <> b.id
WHERE a.section = 'Opening hours'
ORDER BY a.embedding <=> b.embedding
LIMIT 3;

-- 2. Which model built the vectors, and how many dimensions do they have?
SELECT embedding_model, count(*) AS chunks, vector_dims(embedding) AS dimensions
FROM search.chunks
GROUP BY embedding_model, vector_dims(embedding);

-- 3. The plan with the default settings (with 12 rows the planner usually prefers a sequential scan)
EXPLAIN
SELECT id FROM search.chunks
ORDER BY embedding <=> (SELECT embedding FROM search.chunks WHERE section = 'Opening hours')
LIMIT 3;

-- 4. The same query with sequential scans discouraged, to see whether the HNSW index can be used
SET enable_seqscan = off;
EXPLAIN
SELECT id FROM search.chunks
ORDER BY embedding <=> (SELECT embedding FROM search.chunks WHERE section = 'Opening hours')
LIMIT 3;
RESET enable_seqscan;

-- 5. The recall knob of the HNSW index: how many candidates a query inspects
SHOW hnsw.ef_search;

-- 6. How big are the table and the index?
SELECT pg_size_pretty(pg_table_size('search.chunks')) AS table_size,
       pg_size_pretty(pg_relation_size('search.chunks_embedding_hnsw')) AS index_size;
