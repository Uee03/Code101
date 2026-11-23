# Ollama 101 - Phase 2: building with Ollama

**Draft: written (not run).** Programs, model commands and API requests have not been executed by the author.
A static check compares text and source only; it is not runtime verification. All tutorial front matter remains `verified: not yet run`.

## Audience and prerequisites
Finish Python 101 and Ollama lessons 01-04. Python 3.12+ and a native Ollama server on loopback.
Windows, macOS or Linux, supported GPU or CPU-only; never Docker. No pip install or third-party Python library.
Download sizes are not memory requirements. Use short prompts and allow slow CPU first loads.
This phase is self-contained source: the ten-sentence collection, full request JSON and full Modelfile are all included.
It does not rely on copying a Python module from phase 1; the base chat model must already be downloaded.

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**. Open `Code101-main/source/ollama/101-zero-to-hero/phase-2-building-with-ollama`.
Generated archives: `dist/packs/ollama-101-phase-2-building-with-ollama.zip` and `dist/packs/ollama-101-all.zip`.
These are build artifacts, not a claim that a release download exists.
Windows: right-click ZIP > **Extract All > Extract**. macOS: double-click. Linux: choose **Extract** in an archive manager.
Work in an extracted folder, never inside the ZIP. Tutorials are in the repository under `tutorials/ollama/101-zero-to-hero/phase-2-building-with-ollama/`.

## Lessons
| Lesson | Finished source | What it adds |
|---|---|---|
| 05 Python chat client | code/chat.py | One answer or streamed NDJSON; no conversation history |
| 06 Prompting basics | code/prompts.py and request.json | System/roles/examples, temperature and two-layer JSON validation |
| 07 Embeddings search | code/search.py and sentences.json | Ten documents, one query, cosine similarity, top three source sentences |
| 08 Conversation assistant | code/assistant.py and Modelfile | Locally created model recipe, bounded in-RAM turns, reset, no logging/tools |

Every lesson also owns `exercise/starter`, `exercise/solution`, `verify.json`.
Copy a starter folder itself into your own lesson folder and rename it `exercise`; do not create an extra nested starter folder.
Keep companion JSON/Modelfile files beside their Python file. Source and full instructions are also shown in each tutorial.
Suggested personal folders: `~/code101/ollama05` through `~/code101/ollama08`.

## Run deliberately, as a learner (not author verification)
Start in a lesson's `code` folder, or the personal folder containing the copied complete files.
- 05 Windows: `python chat.py`; macOS/Linux: `python3 chat.py`. Add `--stream` to choose NDJSON. Enter public/invented text.
- 06 Windows: `python prompts.py`; macOS/Linux: `python3 prompts.py`. Keep request.json beside prompts.py. Inspect fields, not exact answer text.
- 07 After approving/checking disk, native `ollama pull nomic-embed-text:v1.5`; then Windows `python search.py`, macOS/Linux `python3 search.py`.
  Keep sentences.json beside search.py. Enter a query; scores/order vary and are not probabilities.
- 08 From the folder containing Modelfile, native `ollama create code101-study:local -f Modelfile`, then Windows `python assistant.py`, macOS/Linux `python3 assistant.py`.
  The custom name is a local alias created here, not a public-library tag. /reset clears the Python transcript; /bye exits. Changes to Modelfile require another explicit create.

Before model commands, use passive process/port/API checks from lesson 02, then deliberately start the native app/service only if needed.
Never have this code start a server, install a package or pull a model on import or while handling a failed request.
Exit client input with Ctrl+C if needed. Server/model shutdown and optional removal are explicit in lessons 02/03/08; clients do not stop the native app automatically.
Complete the mixed review in lesson 08.

## Checked models and APIs, 2026-11-23
- `llama3.2:1b`, about 1.3 GB, https://ollama.com/library/llama3.2
- `nomic-embed-text:v1.5`, about 274 MB, embedding only, https://ollama.com/library/nomic-embed-text
- `/api/chat`: messages and message.content; true streaming is one JSON event per line.
- `/api/embed`: input and embeddings (one vector per input); not the deprecated /api/embeddings shape.
- Nomic's model-specific search_document/search_query prefixes: https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
- `format` and structured output: https://docs.ollama.com/capabilities/structured-outputs
- Modelfile defaults: https://docs.ollama.com/modelfile

## Safety and verification
Fixed loopback-only Python URLs, explicit timeouts, disabled environment proxy forwarding and no prompt/response file logs.
Ollama's local API has no built-in authentication. Do not bind it publicly, open the firewall or create tunnels.
Output is untrusted text; no model-generated shell execution or file-writing tools. System prompts are not injection-proof controls.
Never use private text. Reset does not securely erase terminal scrollback, OS memory or another program's records.
Answers vary. JSON SHAPES are illustrative; no generated answer, ranking or timing is a fixed expected output.
All eight track verify.json files have empty steps/cleanup and perform no runtime work. Runtime status remains UNVERIFIED.
The static check result is recorded in `tutorials/ollama/_STATE.md`. No packages, weights, installers, secrets or art are bundled (`assets: []`).

Static source/text check recorded 2026-11-23: **8 static-checked (not run), 0 failed** across both phases. No program was executed, and no runtime success is claimed.
