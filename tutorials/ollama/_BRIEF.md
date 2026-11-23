# Ollama track brief

Level: **101 Zero to Hero**. Native Ollama only, on Windows, macOS or Linux. Never Docker.
Audience: complete beginners; lessons 01-04 need no coding experience. Finish Python 101 before 05-08.
Eight lessons, two phases. This requested introductory scope deliberately brings small examples of
structured output, embeddings and a Modelfile forward from the broader curriculum's 201 outline.
No claim that these examples are production-ready or that every GPU is supported. CPU-only is valid.

## Outcomes and route
| Phase | Lesson | Main outcome |
|---|---|---|
| 1 first-steps | 01 What a local LLM is | Explain local inference, resources, privacy and hallucinations |
| 1 first-steps | 02 Install and check Ollama on your OS | Install natively and inspect health without auto-starting the app |
| 1 first-steps | 03 Pull and chat with a model in the terminal | Manage model disk storage and interpret processor placement |
| 1 first-steps | 04 Talking to the REST API | Send generate/chat requests and recognise JSON versus NDJSON |
| 2 building-with-ollama | 05 Python: a standard-library chat client | Read complete replies and streamed NDJSON safely |
| 2 building-with-ollama | 06 Prompting basics | Use roles, examples, temperature and validated structured JSON |
| 2 building-with-ollama | 07 Embeddings and tiny semantic search | Rank ten sentences using embeddings and cosine similarity |
| 2 building-with-ollama | 08 Project: a conversation assistant | Bound in-memory history and use a complete custom Modelfile |

## Checked models, 2026-11-23
- `llama3.2:1b`: approximately 1.3 GB download, text/chat, https://ollama.com/library/llama3.2
- `nomic-embed-text:v1.5`: approximately 274 MB download, embeddings only, https://ollama.com/library/nomic-embed-text
- `code101-study:local` is NOT a library tag: lesson 08 explicitly creates this local alias from `llama3.2:1b`.
Tags are explicit but not immutable content hashes. Re-check the library before a later revision.
Download size is not a RAM/VRAM requirement. Local tags only; no cloud model, account, API key or paid service.

## Tier 1 sources (checked 2026-11-23)
- https://docs.ollama.com/windows
- https://docs.ollama.com/macos
- https://docs.ollama.com/linux
- https://docs.ollama.com/gpu
- https://docs.ollama.com/faq
- https://docs.ollama.com/api/generate
- https://docs.ollama.com/api/chat
- https://docs.ollama.com/api/embed
- https://docs.ollama.com/api/streaming
- https://docs.ollama.com/capabilities/structured-outputs
- https://docs.ollama.com/modelfile
- https://ollama.com/install.ps1 (read only; not executed)
- https://ollama.com/install.sh (read only; not executed)
- https://ollama.com/library/llama3.2
- https://ollama.com/library/nomic-embed-text
- Model author's task-prefix instructions: https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
- Python standard library: https://docs.python.org/3/library/urllib.request.html and https://docs.python.org/3/library/json.html

## Authoring and verification boundary
No Ollama command, installation, model download, API request, example program or smoke test is run by the author.
Only the repository static verifier and explicitly permitted ZIP pack builder may run.
Every lesson is `verified: not yet run`; state is `written (not run)`; runtime verification remains UNVERIFIED.
Response examples show documented JSON SHAPES with placeholders, not captured or guaranteed model answers.
Each verify.json has empty steps and cleanup: even a later ordinary verification cannot start Ollama accidentally.
Static success proves source/text consistency only. No art is used (`assets: []`).
