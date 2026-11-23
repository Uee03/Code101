CREATE EXTENSION IF NOT EXISTS vector;
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE FUNCTION app.attempt(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    v_rows bigint;
BEGIN
    EXECUTE p_sql;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN 'ok:' || v_rows;
EXCEPTION WHEN OTHERS THEN
    RETURN 'err:' || SQLSTATE;
END
$$;
CREATE TABLE app.articles (
    article_id integer NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    embedding vector(3) NOT NULL,
    search tsvector GENERATED ALWAYS AS (to_tsvector('english', title || ' ' || body)) STORED,
    CONSTRAINT pk_articles PRIMARY KEY (article_id)
);
INSERT INTO app.articles (article_id, title, body, embedding) VALUES
    (1, 'Vacuum basics', 'Autovacuum removes dead rows and updates statistics', '[1,0,0]'),
    (2, 'Index tuning', 'Choose indexes from the query workload', '[0.9,0.1,0]'),
    (3, 'Replication', 'Standby servers replay the write ahead log', '[0,1,0]'),
    (4, 'Vector search', 'Embeddings store meaning as numbers for similarity search', '[0,0,1]');
