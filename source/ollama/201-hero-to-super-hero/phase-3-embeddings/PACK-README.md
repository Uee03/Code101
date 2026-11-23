# Ollama 201 - Phase 3: embeddings

**Draft: written (not run).** No Docker, Postgres, Ollama, pip or program was executed by the author. A static check compares lesson text with source files only; it is not runtime verification. Every lesson's front matter says `verified: not yet run`.

## Audience and prerequisites
Finish phases 1 and 2, Databases 101 and Docker 101 (Compose, healthchecks). Python 3.12+, native Ollama (never Docker) with `nomic-embed-text:v1.5` (about 274 MB, checked 2026-11-23), Docker with the Compose plugin for Postgres.

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**, then open `Code101-main/source/ollama/201-hero-to-super-hero/phase-3-embeddings`.
Generated archives (build artifacts): `dist/packs/ollama-201-phase-3-embeddings.zip` and `dist/packs/ollama-201-all.zip`.
Windows: right-click ZIP > **Extract All**. macOS: double-click. Linux: `unzip`. Work in an extracted folder.

## Lessons
| Lesson | Finished source | What it adds |
|---|---|---|
| 07 Embeddings in depth | `textutil.py`, `embed_lab.py`, `handbook.txt`, `questions.json`, tests | Normalisation, prefixes, chunk-size experiment on your own questions |
| 08 Vector search with pgvector | `docker-compose.yml`, `.env.example`, `initdb/01-schema.sql`, `db.py`, `ingest.py`, `search.py`, `queries.sql`, `notes.json`, `requirements.txt` | Postgres 17 + pgvector 0.8.7, HNSW index, parameterised SQL |
| 09 Project: semantic search CLI | `semsearch.py`, sample `docs/`, tests, plus byte-identical copies of shared files | Ingest, search, stats, reset with safe file handling |

Each lesson also owns `exercise/starter`, `exercise/solution` and `verify.json`.

## Run deliberately, as a learner
- Offline checks need neither Ollama nor Docker: `python -m unittest` in a lesson's `code` folder (lessons 07, 08, 09).
- Lessons 08 and 09: copy `.env.example` to `.env` and choose a password used nowhere else; create a virtual environment and run `python -m pip install -r requirements.txt` (`psycopg[binary]==3.3.9`; pip creates the environment, no lockfile ships). Start with `docker compose up -d --wait`; stop with `docker compose down` (add `-v` only to delete the data).
- The image is `pgvector/pgvector:0.8.7-pg17`, checked on Docker Hub 2026-11-23. Host port 5432 is shared with the Databases track and the capstone platform: run one stack at a time or change `POSTGRES_PORT` in `.env`.
- Lessons 08 and 09 use the same Compose project name and volume; start lesson 09 from an empty database (`docker compose down -v` in lesson 08's folder, or `semsearch.py reset --yes`).

## Safety and honesty
The database is published on `127.0.0.1` only. All SQL values are passed as parameters. `.env` is never committed. Use invented or public text only: the database stores a full copy of everything ingested. Scores, rankings and hit counts are never shown as expected output; they depend on the model build and your machine.
