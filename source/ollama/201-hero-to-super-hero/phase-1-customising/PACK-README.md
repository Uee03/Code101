# Ollama 201 - Phase 1: customising

**Draft: written (not run).** No model command, API call or program was executed by the author. A static check compares lesson text with source files only; it is not runtime verification. Every lesson's front matter says `verified: not yet run`.

## Audience and prerequisites
Finish Ollama 101 (all eight lessons) and Python 101. Python 3.12+, a native Ollama server on `127.0.0.1:11434`. Never Docker for Ollama. No `pip install` in this phase: standard library only.

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**, then open `Code101-main/source/ollama/201-hero-to-super-hero/phase-1-customising`.
Generated archives (build artifacts, not releases): `dist/packs/ollama-201-phase-1-customising.zip` and `dist/packs/ollama-201-all.zip`.
Windows: right-click ZIP > **Extract All**. macOS: double-click. Linux: `unzip` or your archive manager. Work in an extracted folder, never inside the ZIP.
Lesson text is in the repository under `tutorials/ollama/201-hero-to-super-hero/phase-1-customising/`.

## Lessons
| Lesson | Finished source | What it adds |
|---|---|---|
| 01 Modelfile in depth | `Modelfile.reviewer`, `Modelfile.template`, `modelfile_lint.py`, tests, `show_model.py` | Parameters, system prompt, messages, template; an offline linter |
| 02 Choosing and comparing models | `compare.py`, `models.json`, `prompts.json`, tests | Timing harness with `time.perf_counter`; cold versus warm; decision record |
| 03 Structured output and validation | `triage.py`, `schema.json`, `validate.py`, tests | `format` with a JSON schema, a tested validator, a bounded retry |

`ollama_http.py` is identical in every lesson folder (written once in lesson 01, copied unchanged). Each lesson also owns `exercise/starter`, `exercise/solution` and `verify.json`. Copy a starter folder itself into your own lesson folder and rename it `try01`.

## Run deliberately, as a learner
Offline checks need no server: in a lesson's `code` folder run `python -m unittest` (Windows `python`, macOS/Linux `python3`); in lesson 01 also `python modelfile_lint.py Modelfile.reviewer`.
Model steps need checked tags (2026-11-23): `llama3.2:1b` (1.3 GB), `llama3.2:1b-instruct-q4_K_M` (808 MB), `llama3.2:3b` (2.0 GB). Check free disk space before every pull. Use passive health checks (101 lesson 02) before any command that could start the app.

## Safety and honesty
Fixed loopback URLs, explicit timeouts, no proxy forwarding, no prompt or response logging. Ollama has no built-in authentication: never bind it publicly. Replies are model output and vary: no lesson shows a model answer or a timing as expected output, only shapes with placeholders. Measurements are for you to take on your machine.
