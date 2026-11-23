CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS search;

CREATE TABLE search.documents (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source       text        NOT NULL UNIQUE,
    title        text        NOT NULL,
    content_hash text        NOT NULL,
    ingested_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE search.chunks (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    document_id     bigint      NOT NULL REFERENCES search.documents (id) ON DELETE CASCADE,
    chunk_index     integer     NOT NULL CHECK (chunk_index >= 0),
    section         text        NOT NULL DEFAULT '',
    content         text        NOT NULL,
    embedding_model text        NOT NULL,
    embedding       vector(768) NOT NULL,
    UNIQUE (document_id, chunk_index)
);

CREATE INDEX chunks_embedding_hnsw
    ON search.chunks
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
