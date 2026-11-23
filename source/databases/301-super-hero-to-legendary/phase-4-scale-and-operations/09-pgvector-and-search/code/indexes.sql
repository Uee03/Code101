\set ON_ERROR_STOP on
DROP INDEX IF EXISTS app.ix_articles_embedding_hnsw;
DROP INDEX IF EXISTS app.ix_articles_embedding_ivfflat;
DROP INDEX IF EXISTS app.ix_articles_search;
CREATE INDEX ix_articles_embedding_hnsw ON app.articles
    USING hnsw (embedding vector_l2_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX ix_articles_search ON app.articles USING gin (search);
ANALYZE app.articles;
SET hnsw.ef_search = 40;
EXPLAIN (COSTS OFF)
SELECT article_id FROM app.articles ORDER BY embedding <-> '[1,0,0]' LIMIT 2;
EXPLAIN (COSTS OFF)
SELECT article_id FROM app.articles WHERE search @@ websearch_to_tsquery('english', 'search');
DROP INDEX app.ix_articles_embedding_hnsw;
CREATE INDEX ix_articles_embedding_ivfflat ON app.articles
    USING ivfflat (embedding vector_l2_ops) WITH (lists = 1);
SET ivfflat.probes = 1;
EXPLAIN (COSTS OFF)
SELECT article_id FROM app.articles ORDER BY embedding <-> '[1,0,0]' LIMIT 2;
