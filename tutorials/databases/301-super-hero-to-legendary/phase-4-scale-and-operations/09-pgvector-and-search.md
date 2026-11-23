---
track: databases
level: 301
phase: 4
phase_name: scale-and-operations
lesson: 09
title: "pgvector and search: embeddings, ivfflat and hnsw indexes, full-text search"
time: 105 min
prerequisites: [301.1.01, 301.3.07]
versions: { postgres_image: "pgvector/pgvector:0.8.7-pg17-trixie", postgresql: "17", pgvector: "0.8.7", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/09-pgvector-and-search/
assets: []
---

# 09. pgvector and search: embeddings, ivfflat and hnsw indexes, full-text search

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Store embeddings in a `vector` column, choose a distance operator, and predict the nearest-neighbour order for a tiny hand-computed example.
- Choose between exact search, an `hnsw` index and an `ivfflat` index with the trade-offs in recall, build cost, memory and filtering, and say what to measure.
- Build and query PostgreSQL full-text search (`tsvector`, `websearch_to_tsquery`, GIN), and combine it with vector ordering for hybrid search.
- Decide when each of full-text, trigram and vector search is the right tool, and when neither belongs in the database.

## Recap
- Lesson 01: why is an index a hypothesis rather than a guaranteed speedup?
  <details><summary>Answer</summary>It helps only for predicates and volumes where it is selective, and costs writes, space and maintenance.</details>
- Ollama 101 lesson 07: what is an embedding?
  <details><summary>Answer</summary>A list of numbers representing meaning, so that similar texts have nearby vectors; see the [Ollama embeddings lesson](../../../ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search.md).</details>

## Why it matters
Search is where "just add a column" turns into a product feature. Keyword search finds the words you typed, vector search finds meaning, and users expect both. Keeping them inside PostgreSQL gives transactions, joins, permissions and backups for free, at the cost of competing with your OLTP workload for memory and CPU. The skill is knowing the limits: approximate indexes return approximate answers, filters interact badly with them, and embeddings tie you to a model.

## What you will build
Four articles with hand-chosen three-dimensional "embeddings" so you can compute distances yourself, a generated `tsvector` column for full-text search, a report of distances and matches derived by hand, and a separate script that creates `hnsw`, `ivfflat` and GIN indexes so you can read the plans. Real embeddings come from a model such as the one in the Ollama track: they have hundreds of dimensions, and the lab says so rather than pretending otherwise.

## Before you start
- Finished lessons 01 and 07 of this level (plans, tenants) and the [Ollama 101 embeddings lesson](../../../ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search.md) (optional but recommended). No Ollama install is needed for this lab.
- Docker with Compose. **This lesson uses a different image**: the official `postgres:17-alpine` image does not include pgvector, so the Compose file names `pgvector/pgvector:0.8.7-pg17-trixie`, the image published by the pgvector project (PostgreSQL 17 on Debian "trixie"). Check the tags on the [pgvector README](https://github.com/pgvector/pgvector#docker) (which documents the floating `pg17` tag) and Docker Hub before you rely on this exact tag; pinning a version keeps behaviour repeatable. The first start downloads a larger image than the Alpine one.
- Time: 105 minutes. Two sittings: break after Step 4.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/09-pgvector-and-search/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-4-scale-and-operations.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; distances are computed by hand and rounded to three decimals.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 08, Step 1](08-replication-and-high-availability.md#step-1-prepare-the-workspace) (genuinely identical) with the lesson folder `09-pgvector-and-search`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-4-scale-and-operations\09-pgvector-and-search\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-4-scale-and-operations/09-pgvector-and-search/code"
```

### Step 2. Save the complete Compose configuration
This file differs from the other 301 Compose files in exactly one line: the `image`.

**File: `code/docker-compose.yml`**
```yaml
services:
  db:
    image: pgvector/pgvector:0.8.7-pg17-trixie
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATABASE: ${POSTGRES_DB}
      PGUSER: ${POSTGRES_USER}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - .:/scripts:ro
      - ../exercise:/exercises:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 2s
      timeout: 3s
      retries: 30
      start_period: 5s
volumes:
  pg_data:
```

| Line | Meaning and what changing it does |
|---|---|
| `image: pgvector/pgvector:0.8.7-pg17-trixie` | The pgvector project's image: the official PostgreSQL 17 image plus the extension files. The tag encodes the pgvector version, the PostgreSQL major version and the Debian release. Moving to another PostgreSQL major version needs a dump and restore or an upgrade, not just a tag change. |
| Everything else | Identical to [lesson 02, Step 2](../phase-1-performance/02-statistics-vacuum-and-bloat.md#step-2-save-the-complete-compose-configuration); the line-by-line table is in [lesson 01, Step 2](../phase-1-performance/01-query-tuning-method.md#step-2-save-the-complete-compose-configuration). |

The extension is **available** in the image but not **enabled**: each database needs `CREATE EXTENSION vector;` once (the setup script does it). No Dockerfile; no art (`assets: []`).

### Step 3. Create the environment files
**File: `code/.env.example`**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

**File: `code/.gitignore`**
```gitignore
.env
*.dump
```

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp .env.example .env
```

Expected output, not yet run: nothing printed.

### Step 4. Learn the model, then save the files
New terms. An **embedding** is a vector (an ordered list of numbers) that a model produces for a piece of text, so that texts with similar meaning get nearby vectors. **Dimension** is the length of the vector. **Distance operators** in pgvector: `<->` L2 (straight-line) distance, `<=>` cosine distance (one minus the cosine of the angle; ignores length), `<#>` **negative** inner product (negative because PostgreSQL index scans only go in ascending order). **Nearest-neighbour search** orders rows by distance to a query vector and takes the first *k*. **Exact search** compares the query with every row (perfect **recall**, the fraction of true neighbours found). **Approximate nearest-neighbour (ANN)** indexes trade recall for speed. **`hnsw`** builds a multi-layer graph; **`ivfflat`** clusters vectors into **lists** and searches only the nearest lists (**probes**). **Full-text search** matches words after **stemming** (reducing words to a root) using a **`tsvector`** (the processed document) and a **`tsquery`** (the processed query). **Hybrid search** combines keyword and vector signals.

**The toy vectors.** Real embeddings have hundreds or thousands of dimensions (check the length your model returns, and store the model name beside the vectors). The lab uses three dimensions so you can check every number: article 1 `[1,0,0]` (maintenance), article 2 `[0.9,0.1,0]` (nearly the same direction), article 3 `[0,1,0]` and article 4 `[0,0,1]` (unrelated directions). The query vector is `[1,0,0]`.

**Hand arithmetic.** L2 distance to `[1,0,0]`: article 1 is 0; article 2 is the square root of (0.1 squared plus 0.1 squared) = 0.1414; articles 3 and 4 are the square root of 2 = 1.4142 (a tie, broken by article id). Cosine distance: article 1 is 0; article 2 is 1 - 0.9 / sqrt(0.82) = 1 - 0.99388 = 0.00612; articles 3 and 4 are orthogonal to the query, so the cosine is 0 and the distance is 1.

**File: `code/setup.sql`**
```sql
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
```

Line by line. `CREATE EXTENSION IF NOT EXISTS vector` enables pgvector in this database (extensions are per database; the extension lives in the default schema and survives the schema reset). `vector(3)` declares the dimension: PostgreSQL rejects other lengths. `search` is a **generated column**: PostgreSQL computes `to_tsvector('english', ...)` from the title and body whenever a row is written, and stores it, so the application never maintains it. The two-argument form names the text-search **configuration** (language rules for stemming and stop words), which makes the expression immutable as a generated column and an index requires; the one-argument form depends on a setting and is rejected there.

**File: `code/lesson.sql`**
```sql
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
```

Reading the script. The first query prints both distances for every article, in L2 order. The second takes the nearest two: the standard `ORDER BY distance LIMIT k` shape, with an explicit tie-break so the result is deterministic. The third shows the dimension and the storage arithmetic: pgvector stores each vector in **4 bytes per dimension plus 8 bytes** of overhead, so one 1,536-dimension embedding takes 6,152 bytes, and a million of them take about 6.2 GB before indexes. The fourth tries to insert a two-dimension vector into a three-dimension column. The fifth runs five keyword searches; `websearch_to_tsquery` accepts search-box syntax (words, quoted phrases, `or`, a leading minus), and the stemmer makes `indexing` match `Index` and `indexes`, and drops stop words such as `the`. The last query is **hybrid**: keyword filter first, then vector order.

**File: `code/indexes.sql`**
```sql
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
```

This script only creates indexes and prints plans; nothing is asserted, because with four rows the planner may well prefer a sequential scan, and that is correct. The parameters: `m` is the number of connections per graph node (higher: better recall, bigger index), `ef_construction` the candidate list while building (higher: better graph, slower build), `hnsw.ef_search` the candidate list while searching (higher: better recall, slower query), `lists` the number of clusters for `ivfflat` (a rule of thumb from the pgvector documentation is rows / 1,000 up to a million rows, then the square root of the rows) and `ivfflat.probes` the clusters visited per query (higher: better recall, slower). The `vector_l2_ops` operator class must match the operator in the query: cosine distance needs `vector_cosine_ops`, negative inner product `vector_ip_ops`; a mismatched index is not used. The index is named, so it can be dropped without guessing.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-09 up -d --wait
```

Expected output, not yet run: image pulled on first use (larger than Alpine), network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-09 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 09`.

## Run it
**Predict first.** (a) In what order do the four articles come back for the query `[1,0,0]`, and what is the cosine distance of article 2? (b) Which articles match `dead rows`, `indexing` and `missing`? (c) What happens when you insert a two-dimension vector? (d) In the hybrid query, which article is returned first?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
article_id|l2|cosine
1|0.000|0.000
2|0.141|0.006
3|1.414|1.000
4|1.414|1.000
nearest_two
1,2
dims|bytes_for_1536_dims
3|6152
wrong_dimension
err:22000
q|matches
dead rows|1
indexing|2
missing|(null)
search|4
the log|3
article_id
2
3
```

Why: distances follow the arithmetic above, rounded to three decimals; the tie between articles 3 and 4 is broken by id. The wrong-dimension insert fails with SQLSTATE `22000` (data exception; the pgvector message says it expected 3 dimensions, not 2). `dead rows` is an AND of the stems `dead` and `row`, found only in article 1. `indexing` stems to `index`, matching article 2 through both `Index` and `indexes`. `missing` matches nothing, shown as `(null)` because `string_agg` over zero rows is null. `the log` becomes just `log` after stop-word removal, matching article 3. In the hybrid query the keyword filter keeps articles 2 and 3, and vector order puts 2 first.

### Read the plans (not asserted)
After Run it:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/indexes.sql
```

Expected output, not yet run: three plans, whose text is not predicted. Look for: an index scan on the `hnsw` or `ivfflat` index versus a sequential scan with a sort; a bitmap scan on the GIN index; and notices from the server when you create an `ivfflat` index on very little data (typically a notice that few rows give poor recall). On four rows a sequential scan is the right plan; repeat on tens of thousands of real embeddings before judging an index.

## How it works
**Exact first.** Without an ANN index pgvector scans every vector: perfect recall and cost proportional to rows times dimensions. For up to tens of thousands of rows (measure it), exact search with a good filter is often fast enough and has no tuning. Add an ANN index when exact search misses your latency budget.

**`hnsw` versus `ivfflat`.**

| Aspect | `hnsw` | `ivfflat` |
|---|---|---|
| Recall for a given speed | Better | Lower |
| Build time and memory | Slower, more memory (builds fastest when the graph fits in `maintenance_work_mem`) | Faster, less memory |
| Needs data before building | No (can be built empty) | Yes: lists are computed from existing rows, so build after loading representative data |
| Maintenance | Inserts update the graph; vacuum can be slow (reindexing first helps) | Lists become stale as data drifts; rebuild periodically |
| Tuning knobs | `m`, `ef_construction` at build; `hnsw.ef_search` at query | `lists` at build; `ivfflat.probes` at query |
| Dimension limit for indexing `vector` | 2,000 | 2,000 (use `halfvec` or other options for larger) |

**Filters and ANN do not mix for free.** An ANN index returns its best candidates, **then** your `WHERE` clause filters them. With a selective filter you may get fewer than *k* rows, or the wrong ones. Options: exact search with a B-tree on the filter column when the filter is selective; partial or partitioned indexes per tenant or category (lesson 03); `hnsw.iterative_scan` or `ivfflat.iterative_scan` (pgvector 0.8.0 and later) so the scan continues until enough rows pass the filter; and raising `ef_search` or `probes`. Row-level security (lesson 06) is a filter too: test it with the ANN index in place. A shared ANN index across tenants also lets one tenant's vectors influence another's recall; the pgvector documentation suggests partitioning by tenant or using separate tables for isolation.

**Measure recall, not just speed.** Take a sample of queries, compute the exact top *k* with the index disabled for the transaction (for example `BEGIN; SET LOCAL enable_indexscan = off; ...; COMMIT;`), run the same queries with the index, and report the overlap (recall at *k*) with latency at several `ef_search` or `probes` values. Pick the cheapest setting that meets your quality target on **your** data. Use a representative sample: the toy vectors here say nothing about real recall.

**Embeddings are an operational dependency.** The vectors depend on the model and its version: store the model name and dimension beside them, never compare vectors from different models, and plan a re-embedding job (and a cutover) for every model change. Chunk long documents (a single vector per book is useless) and store the chunk text or a reference. Keep a hash of the source text so you re-embed only what changed. Producing embeddings is a call to a model server (for example Ollama locally, as in the Ollama track) or a hosted API: handle timeouts, batching and failures outside the database transaction. Treat embeddings as sensitive as the text they represent: they can leak information about it.

**Size.** A 1,536-dimension `vector` is 6,152 bytes; `halfvec` (half precision) uses 2 bytes per dimension and indexes more dimensions; binary quantisation and re-ranking shrink indexes further at a recall cost. Large vectors are stored out of line (TOAST); the pgvector documentation recommends storage settings for the best performance. Index and table size should be compared to **memory**: an ANN index that does not fit in RAM can be slow.

**Full-text search in PostgreSQL.** Strengths: transactional, no extra service, stemming, stop words, phrase and boolean queries, ranking (`ts_rank`, `ts_rank_cd`), weights (`setweight` to favour titles), highlighting (`ts_headline`). Index the `tsvector` with GIN. Limits: language configuration per query, no typo tolerance, relevance tuning is basic. For **partial words and typos** use the `pg_trgm` extension (trigram GIN or GiST indexes), as the capstone platform does for task titles. For large-scale relevance engineering, faceting and analytics, a dedicated search engine is the better tool.

**Which tool when.**

| Need | Use |
|---|---|
| Exact keywords, filters, ranking by text match | Full-text search (GIN) |
| Substring, prefix, typo-tolerant matching | `pg_trgm` |
| "Similar meaning" with different words | Vector search (exact, then ANN) |
| Best of both | Hybrid: filter or rank with full-text, rank with vectors, fuse ranks (for example reciprocal rank fusion) in SQL or the application |
| Billions of vectors, strict latency, heavy re-ranking | A dedicated vector or search system, or sharding |

**Why this, not that.** Do not index first; measure exact search on your data. Use the distance operator your embedding model's documentation recommends, and create the index with the matching operator class. Do not mix embeddings from two models in one column. Do not use ANN when the application needs exact answers.

**Measurements to take (production checklist).**
- [ ] Recall at *k* and p95 latency for representative queries at several `ef_search` or `probes` values.
- [ ] Index build time, peak memory and `maintenance_work_mem` used; index size against RAM.
- [ ] Insert and update latency with the index in place; vacuum duration on the table.
- [ ] Filtered queries: rows returned versus requested; effect of iterative scans.
- [ ] Re-embedding rehearsal: time, cost, and the cutover plan (dual columns or a new table).
- [ ] Backup size growth (vectors are large) and restore time (lesson 08).
- [ ] The embedding model, version and dimension recorded per row or per table.

## Try it
Keep `db` running.

1. **Guided:** In the starter, replace the placeholder order with the cosine distance to the query vector `[0.1,0.9,0]`, nearest first, ties by article id.

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

**File: `exercise/starter/exercise.sql`** (copy to `code/exercise.sql`)
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: order the article ids from nearest to farthest by COSINE distance (operator <=>)
-- to the query vector '[0.1,0.9,0]'. Break ties by article_id.
SELECT string_agg(article_id::text, ',' ORDER BY article_id) AS by_cosine FROM app.articles;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand. The query points almost straight along the second axis. Article 3 `[0,1,0]` is nearly parallel (cosine distance about 0.006); article 2 has cosine distance about 0.78; article 1 about 0.89; article 4 is orthogonal (distance 1). The untouched starter prints the ids in numeric order.

**Expected output, not yet run:**

```text
by_cosine
3,2,1,4
```

3. **Change:** Run the same ordering with the L2 operator `<->`. Predict first whether the order changes, then compare. Explain in a sentence when L2 and cosine disagree (vectors of different lengths).
4. **Stretch (optional, no single answer):** You have 3 million 768-dimension chunk embeddings from the Ollama model in the Ollama track, a `tenant_id` filter on every query, and a p95 target of 50 ms. Choose exact versus `hnsw` versus `ivfflat`, how you handle the tenant filter, and the experiment (sizes, recall measurement, memory) that decides it.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT string_agg(article_id::text, ',' ORDER BY embedding <=> '[0.1,0.9,0]', article_id) AS by_cosine
FROM app.articles;
```

For the change rung: with L2 the distances to `[0.1,0.9,0]` are 1.273 (article 1), 1.131 (article 2), 0.141 (article 3), 1.349 (article 4), so the order is 3, 2, 1, 4: the same here because all vectors have similar lengths; L2 and cosine disagree when vector lengths differ a lot, since L2 is sensitive to length and cosine ignores it. For the stretch rung, a defensible answer: size the index (3,000,000 x (4 x 768 + 8) bytes is about 9.2 GB of vectors alone), compare with RAM, test `hnsw` with `ef_search` sweeps against exact top-k on a sample, handle the tenant filter with a partial index or list partitions per large tenant plus iterative scans for the rest, and decide from measured recall and p95 latency, not from the toy example.

To compare in your workspace, repeat the copy with `solution` instead of `starter`:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\solution\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/solution/exercise.sql ./exercise.sql
```

</details>

### Stop and clean up
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-09 stop
docker compose -p code101-db301-09 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data. The pulled `pgvector` image stays in Docker's cache until you remove it with `docker image rm`.

## Check yourself
1. Which distance operator returns the **negative** inner product, and why negative? <details><summary>Answer</summary>`<#>`; PostgreSQL index scans only support ascending order, so the sign is flipped to make "largest inner product" sort first.</details>
2. Predict the number of bytes for a 768-dimension `vector`. <details><summary>Answer</summary>4 x 768 + 8 = 3,080 bytes.</details>
3. A query with `WHERE tenant_id = 7 ORDER BY embedding <-> $1 LIMIT 10` on an `hnsw` index returns 3 rows. Why, and what do you do? <details><summary>Answer</summary>The index returned its best candidates first and the filter then removed most; use iterative scans, raise `ef_search`, or use a partial or partitioned index, or exact search with a B-tree on `tenant_id`.</details>
4. Find the problem: the team switches to a new embedding model and appends new vectors to the same column. <details><summary>Answer</summary>Vectors from different models are not comparable, and dimensions may differ. Re-embed into a new column or table and switch over.</details>
5. When is full-text search better than vector search? <details><summary>Answer</summary>When users search for exact words, names or codes and you need filters, phrase matching and explainable ranking, without a model dependency.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| An error saying the extension `vector` is not available (typical message) | The container uses the plain `postgres` image | Use the pgvector image from this lesson's Compose file |
| An error saying a vector must have 3 dimensions (typical) | Inserted vector has another length | Match the column's declared dimension |
| The index is never used | Operator class does not match the operator, or no `ORDER BY ... LIMIT`, or the table is tiny | Match `vector_l2_ops` with `<->` (and so on); order directly by the distance; test on realistic row counts |
| `ivfflat` recall is poor | Index built on little or unrepresentative data, too few `probes` | Rebuild after loading data; raise `ivfflat.probes` |
| `generation expression is not immutable` (typical) | `to_tsvector` called without the configuration argument | Use `to_tsvector('english', ...)` |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Start with exact search, measure recall and latency on representative data before adding an ANN index, and record the embedding model and dimension with every vector. Source: [pgvector README](https://github.com/pgvector/pgvector) and [PostgreSQL 17: Full Text Search](https://www.postgresql.org/docs/17/textsearch.html).

## Going further
- [PostgreSQL 17: Text Search Controls](https://www.postgresql.org/docs/17/textsearch-controls.html) and [GIN indexes](https://www.postgresql.org/docs/17/gin.html).
- The Ollama track: [embeddings and a tiny semantic search](../../../ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search.md), which produces the vectors you would store here.
- [Supabase: performance guidance](https://supabase.com/docs/guides/platform/performance) for a hosted view of pgvector workloads (Tier 2).
- Capstone: the platform's `tasks.title` uses a `pg_trgm` GIN index for substring search: see [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).

## Summary
- You stored embeddings, picked distance operators and predicted a nearest-neighbour order by hand.
- You compared exact, `hnsw` and `ivfflat` search and named the filtering, memory and recall trade-offs.
- You built full-text search with a generated `tsvector` and combined it with vector order.
- You listed what to measure before an index or a model change reaches production.

## Next lesson
10. Other engines: SQL Server and SQLite differences, and a production readiness checklist with a review exercise.
