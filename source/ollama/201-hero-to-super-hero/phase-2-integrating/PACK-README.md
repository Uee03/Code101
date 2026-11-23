# Ollama 201 - Phase 2: integrating

**Draft: written (not run).** No dotnet, node, npm, Ollama or program was executed by the author. A static check compares lesson text with source files only; it is not runtime verification. Every lesson's front matter says `verified: not yet run`.

## Audience and prerequisites
Finish phase 1. Lesson 04 needs the .NET SDK from C# 101 (`net11.0`); lesson 05 needs Node.js 26.13.1 and npm 11.20.0 (as in Web 101); lesson 06 needs Python 3.12+. A native Ollama server on `127.0.0.1:11434`; never Docker for Ollama.

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**, then open `Code101-main/source/ollama/201-hero-to-super-hero/phase-2-integrating`.
Generated archives (build artifacts): `dist/packs/ollama-201-phase-2-integrating.zip` and `dist/packs/ollama-201-all.zip`.
Windows: right-click ZIP > **Extract All**. macOS: double-click. Linux: `unzip`. Work in an extracted folder.

## Lessons
| Lesson | Finished source | What it adds |
|---|---|---|
| 04 Calling Ollama from C# | `OllamaDemo.csproj`, `Program.cs`, `Models.cs`, `OllamaApi.cs`, `ChunkParser.cs`, `SelfTest.cs` | `HttpClient`, records, streaming with `ResponseHeadersRead`, cancellation, `--selftest` |
| 05 Calling Ollama from TypeScript | `package.json`, `tsconfig.json`, `src/ollama.ts`, `src/main.ts`, `src/selftest.ts` | `fetch`, `ReadableStream`, a line splitter for NDJSON cut mid-line |
| 06 The OpenAI-compatible endpoint | `openai_compat.py`, tests, `ollama_http.py` | `/v1` chat, streaming SSE, JSON mode, embeddings; what is missing |

Each lesson also owns `exercise/starter`, `exercise/solution` and `verify.json`.

## Run deliberately, as a learner
- 04: in `code`, `dotnet run -- --selftest` needs no server. With a server: `dotnet run -- --stream "your question"`.
- 05: in `code`, `npm install`, `npm run build`, `npm run selftest`, then `npm start`. No lockfile ships: `npm install` creates `package-lock.json`; keep it. On Windows PowerShell, use `npm.cmd` if script execution is blocked.
- 06: in `code`, `python -m unittest`, then `python openai_compat.py models|chat|stream|json|embed`. The `embed` action needs `nomic-embed-text:v1.5` (about 274 MB, checked 2026-11-23).

## Safety and honesty
Loopback URLs only, no proxy forwarding, explicit time budgets, no logging of prompts or replies. A browser page must not call Ollama directly (no authentication). The OpenAI key value is ignored by Ollama and protects nothing. Replies are model output and vary: only shapes are shown. Versions: Node 26.13.1, npm 11.20.0, TypeScript 7.0.2, @types/node 26.6.6 (registry, 2026-11-23).
