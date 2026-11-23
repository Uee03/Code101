# Ollama 301 - Super Hero to Legendary

## Audience and promise
Finished Ollama 201. Eight lessons in three phases, numbering restarted at 01. Trade-offs, failure modes, measurements to take (never numbers supplied), ADR-style decisions, production checklists, security and operations. Native Ollama only; Postgres/pgvector and nginx in temporary Docker containers only.

## Scope and sequence
| Phase | Lesson | Main outcome |
|---|---|---|
| 1 rag | 01 RAG architecture | Two paths, failure-mode table, tested decision core (select, budget, checks, refusal) |
| 1 rag | 02 Pipeline with citations | Real retrieval and generation; cited versus retrieved sources |
| 1 rag | 03 Evaluation | Golden set, hit rate, MRR, answer checks, threshold from data, stored reports |
| 2 agents-and-tools | 04 Tool calling | Schema, loop, allow-list, propose-then-confirm, tool-selection measurement |
| 2 agents-and-tools | 05 Guardrails and privacy | Injection layers, output guard, canary, logging policy as code, red-team trials |
| 3 operating | 06 Serving and scaling | Queue, slots, `keep_alive`, bounded load test, AMD/NVIDIA/Apple notes |
| 3 operating | 07 Security and deployment | Loopback, authenticated allow-listed nginx proxy, TLS variant, review exercise |
| 3 operating | 08 Capstone RAG service | Authenticated loopback service over `capstones/platform` docs, acceptance record, review |

## Checked facts (2026-11-23)
- Models: `llama3.2:3b` 2.0 GB with `tools` capability; `nomic-embed-text:v1.5`; `llama3.2:1b` (lesson 06).
- Docker Hub: `pgvector/pgvector:0.8.7-pg17`, `nginx:1.30.7-alpine`, `httpd:2.4-alpine`. `psycopg[binary]==3.3.9`.
- Docs read: FAQ (concurrency, queue 512 default, `keep_alive`, flash attention, KV cache), gpu, tool-calling, embeddings; pgvector README (iterative scans since 0.8.0).
- Gold labels of lesson 08 were built from text searches of `capstones/platform` on 2026-11-23; learners must re-verify.

## Rules followed
Nothing was run. No model answer, score, timing or attack success rate is shown as expected output. Draft notice and `verified: not yet run` everywhere. `assets: []`. Shared files are byte-identical copies in `skip_lesson_check`.
