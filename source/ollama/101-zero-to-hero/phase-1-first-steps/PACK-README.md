# Ollama 101 - Phase 1: first steps

**Draft: written (not run).** No example, installer, Ollama command or local API call has been executed by the author.
Static consistency checks do not prove runtime correctness. Tutorial front matter remains `verified: not yet run`.

## Audience and prerequisites
Complete beginners. No coding and no Python required in lessons 01-04. Permission to install native background software,
internet for installer/model downloads, and disk/working-memory headroom. GPU optional; CPU-only is supported.
Ollama is always native on Windows, macOS or Linux, never Docker. See lesson 02 for OS requirements and drivers.

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**. Open the extracted `Code101-main/source/ollama/101-zero-to-hero/phase-1-first-steps`.
When built, the smaller phase archive is `dist/packs/ollama-101-phase-1-first-steps.zip`; the combined archive is `dist/packs/ollama-101-all.zip`.
ZIP files are generated artifacts, not assumed committed/downloadable release assets.
Windows: right-click ZIP > **Extract All > Extract**. macOS: double-click. Linux: use the archive manager's **Extract**.
Do not work inside an unextracted ZIP. Open the resulting phase folder.

## Lessons and files
Tutorials: `tutorials/ollama/101-zero-to-hero/phase-1-first-steps/` in the repository; the ZIP contains source, not a copy of every tutorial.

| Lesson | Finished example | Exercise |
|---|---|---|
| 01 What a local LLM is | code/local-plan.md | Public-input planning worksheet |
| 02 Install and check | code/setup-checklist.md | Diagnose an invented stopped-server scenario |
| 03 Pull and chat | code/model-record.md | Choose disk/memory management operations |
| 04 REST API | code/generate.json, chat.json, chat-stream.json | Complete a non-streaming request |

Every lesson folder contains `code/`, `exercise/starter/`, `exercise/solution/`, `verify.json`.
Copy the **starter folder itself** into your own lesson folder and rename the copy `exercise`, not `exercise/starter`.
Full files, exact working folders, save instructions and OS command variants are shown in each tutorial.
Suggested personal folders: `~/code101/ollama01` through `~/code101/ollama04` (PowerShell also accepts `~`).

## How to follow
1. Read lesson 01 and save the plan. Nothing installs there.
2. In lesson 02 choose just your OS's native official installation branch; read the script first.
3. Inspect the executable, process and port, then GET `/api/version`. Do not use list/ps/run as initial health checks: they may launch the app.
4. Start one native app/service intentionally only if needed. Keep loopback-only port 11434; no firewall/tunnel changes.
5. In lesson 03 check disk, then deliberately `ollama pull llama3.2:1b`, and use the exact run/list/ps/stop/rm steps shown there.
6. In lesson 04 create the request JSON files. Use the complete PowerShell Invoke-RestMethod route or curl route from the lesson, not both automatically.
   PowerShell uses curl.exe if choosing curl; macOS/Linux use curl. Set stream false for one object, true for NDJSON.
7. Complete the phase's mixed review in lesson 04. Stop the native app/service using lesson 02 when done; preserve the chat download for phase 2.

## Model and response policy
Live library checked **2026-11-23**: `llama3.2:1b`, about 1.3 GB, https://ollama.com/library/llama3.2.
Download size is not working-memory usage; extra room is essential. No fixed latency or supported-GPU promise.
Read the actual PROCESSOR column in ollama ps: CPU, GPU or a split; successful HTTP alone proves no GPU placement.
All model response examples are SHAPES with variable content, not expected answers or captured output.
Use public/invented text only. Local inference does not protect against local malware, shared screens or chat logging.

## Verification and packaging
Each verify.json intentionally has `requires: []`, `steps: []`, `cleanup: []`: no later verification can accidentally pull models or start Ollama.
Only text/source static consistency is checked for this draft; runtime state is UNVERIFIED. See `tutorials/ollama/_STATE.md` for the recorded check.
No external packages, secrets, model weights, downloaded installer scripts or art are included. Every lesson has `assets: []`.

Static source/text check recorded 2026-11-23: **8 static-checked (not run), 0 failed** across both phases. No program was executed, and no runtime success is claimed.
