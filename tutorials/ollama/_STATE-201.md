# Ollama 201 state

Updated: 2026-11-23. Status of all nine lessons: **written (not run)**. Runtime verification: UNVERIFIED.

| Lesson | Status |
|---|---|
| 201.1.01 Modelfile in depth | written (not run) |
| 201.1.02 Choosing and comparing models | written (not run) |
| 201.1.03 Structured output and validation | written (not run) |
| 201.2.04 Calling Ollama from C# | written (not run) |
| 201.2.05 Calling Ollama from TypeScript | written (not run) |
| 201.2.06 The OpenAI-compatible endpoint | written (not run) |
| 201.3.07 Embeddings in depth | written (not run) |
| 201.3.08 Vector search with pgvector | written (not run) |
| 201.3.09 Project: semantic search CLI | written (not run) |

## Checks
- `python scripts\verify_labs.py --static ollama/201` was run once, before the instruction to stop all checks: all 9 lessons reported STATIC, 0 failed. Edits after that run were limited to one wording change in lesson 02. It was **not** re-run, and `build_packs.py` was not run for 201.
- The static check compares text and source only; it executes nothing.

## Not done / pending
- No runtime run of any lesson. Pending review: C# records deserialisation and `JsonContent.Create`, TypeScript 7 typing of stream reads, psycopg server-side binding of `::vector` strings, nginx-free (201 has none), expected counts of unit tests (13, 9, 11, 6, 4, ...), model-tag availability, Docker Hub tags.
- ZIPs not built. `python scripts/build_packs.py ollama-201` still to run.
- Glossary terms appended to `GLOSSARY.md`.
