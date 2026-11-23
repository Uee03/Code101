# Ollama 201 - Hero to Super Hero

## Audience and promise
Finished Ollama 101 and Python 101; one to two years of experience. Nine lessons in three phases, numbering restarted at 01. Why, "Why this, not that" boxes, offline unit tests with every feature, Mermaid diagrams, exercises in three rungs. Native Ollama only; Postgres with pgvector in a temporary Docker container only.

## Scope and sequence
| Phase | Lesson | Main outcome |
|---|---|---|
| 1 customising | 01 Modelfile in depth | Parameters, system, messages, template; offline linter |
| 1 customising | 02 Choosing and comparing models | Size, quantisation, context; `time.perf_counter` harness; decision record |
| 1 customising | 03 Structured output and validation | `format` schema, tested validator, bounded retry |
| 2 integrating | 04 Calling Ollama from C# | `HttpClient`, streaming with `ResponseHeadersRead`, cancellation |
| 2 integrating | 05 Calling Ollama from TypeScript | `fetch`, NDJSON line splitting across packets |
| 2 integrating | 06 The OpenAI-compatible endpoint | `/v1` chat, SSE, JSON mode, embeddings; gaps; when to use |
| 3 embeddings | 07 Embeddings in depth | Normalisation, prefixes, chunk-size experiment |
| 3 embeddings | 08 Vector search with pgvector | Compose, schema, HNSW, parameterised SQL, honest EXPLAIN |
| 3 embeddings | 09 Project: semantic search CLI | Ingest, search, stats, reset with safe file handling |

## Checked facts (2026-11-23)
- Models (https://ollama.com/library/llama3.2/tags): `llama3.2:1b` 1.3 GB (same digest as `1b-instruct-q8_0`), `llama3.2:1b-instruct-q4_K_M` 808 MB, `llama3.2:3b` 2.0 GB, all 128K listed; `nomic-embed-text:v1.5` 274 MB, 2K context. Default context is 4096 (FAQ).
- Docker Hub: `pgvector/pgvector:0.8.7-pg17`. PyPI: `psycopg` 3.3.9 (Python 3.10+). npm: `typescript` 7.0.2, `@types/node` 26.6.6. .NET `net11.0` as in C# 101.
- Docs read: modelfile, api/chat, api/embed, capabilities (structured outputs, tool calling, embeddings), OpenAI compatibility, FAQ, gpu; pgvector README.

## Rules followed
No code, Ollama, model, API, Docker or smoke test was run by the author. Model answers, scores and timings are never expected output, only shapes with placeholders. Every lesson carries the draft notice and `verified: not yet run`. No lockfiles (pip, npm): the commands that create them are stated. Shared files (`ollama_http.py`, `textutil.py`, `db.py`, compose, schema) are byte-identical copies listed in `skip_lesson_check`. `assets: []`.
