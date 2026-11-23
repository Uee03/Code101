# Ollama 301 - Phase 1: RAG

**Draft: written (not run).** No Docker, Postgres, Ollama, pip or program was executed by the author, and no static check was run on this level. Every lesson's front matter says `verified: not yet run`.

## Audience and prerequisites
Finish Ollama 201 (all three phases). Python 3.12+, native Ollama (never Docker) with `nomic-embed-text:v1.5` and `llama3.2:3b` (tags checked 2026-11-23), Docker with Compose for Postgres 17 + pgvector (`pgvector/pgvector:0.8.7-pg17`, checked on Docker Hub 2026-11-23).

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**, then open `Code101-main/source/ollama/301-super-hero-to-legendary/phase-1-rag`. Generated archives (build artifacts, not yet built for this level): `dist/packs/ollama-301-phase-1-rag.zip`, `ollama-301-all.zip`.

## Lessons
| Lesson | New source | What it adds |
|---|---|---|
| 01 RAG architecture | `rag_core.py`, tests | Selection, budget, prompt layout, citation checks, refusal; failure-mode table |
| 02 Pipeline with citations | `rag_pipeline.py`, `corpus/`, compose, `.env.example` | Real retrieval and generation, cited versus retrieved sources |
| 03 Evaluation | `metrics.py`, `evaluate.py`, `golden.json` | hit rate, MRR, answer checks, threshold from data, stored reports |

Files shared with earlier lessons are byte-identical copies (listed in each lesson). Each lesson has `exercise/starter`, `exercise/solution`, `verify.json`.

## Run deliberately, as a learner
Offline: `python -m unittest` in a lesson's `code` folder (no model or database needed). Live: copy `.env.example` to `.env` with a lab-only password, create a virtual environment, `python -m pip install -r requirements.txt` (pip creates the environment; no lockfile ships), `docker compose up -d --wait`. Port 5432 is shared with other labs: run one stack at a time. Stop with `docker compose down` (`-v` deletes data).

## Safety and honesty
Loopback only. Use invented or public text. Reports contain answers: keep `reports/` private (it is git-ignored). No scores, rankings or timings are shown as expected output.
