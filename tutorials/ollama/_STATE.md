# Ollama track state

Updated: 2026-11-23. Owner scope: tutorials/ollama and source/ollama; generated dist/packs ZIPs explicitly permitted.

| Lesson | Status | Runtime verification |
|---|---|---|
| 101.1.01 What a local LLM is | written (not run) | UNVERIFIED |
| 101.1.02 Install and check Ollama on your OS | written (not run) | UNVERIFIED |
| 101.1.03 Pull and chat with a model in the terminal | written (not run) | UNVERIFIED |
| 101.1.04 Talking to the REST API | written (not run) | UNVERIFIED |
| 101.2.05 Python: a standard-library chat client | written (not run) | UNVERIFIED |
| 101.2.06 Prompting basics | written (not run) | UNVERIFIED |
| 101.2.07 Embeddings and tiny semantic search | written (not run) | UNVERIFIED |
| 101.2.08 Project: a conversation assistant | written (not run) | UNVERIFIED |

## Boundaries
- No runtime toolchain inspection or execution. Ollama server availability intentionally not probed.
- No installation, model pull, process start, HTTP request to localhost, lesson-code execution or smoke test.
- Official documentation and live library pages read on 2026-11-23; model choices recorded in _BRIEF.md.
- All Python uses the standard library, fixed loopback URLs, explicit timeouts, disabled proxy forwarding,
  no request/response logging, and no shell execution of model output.
- All eight verify.json files have `steps: []`; no empty specification implies functional correctness.
- Source and exercise solutions are authored examples, not runtime-verified programs.

## Static and packaging
Static source/text status: **verified** by the allowed static-only check on 2026-11-23. This is not runtime verification.

Command (repository root): `python scripts\verify_labs.py --static ollama/101`.
Actual captured output:

```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/01-what-a-local-llm-is
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/02-install-and-check
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/03-pull-and-chat
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/04-rest-api
[STATIC    ] source/ollama/101-zero-to-hero/phase-2-building-with-ollama/05-python-chat-client
[STATIC    ] source/ollama/101-zero-to-hero/phase-2-building-with-ollama/06-prompting-basics
[STATIC    ] source/ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search
[STATIC    ] source/ollama/101-zero-to-hero/phase-2-building-with-ollama/08-conversation-assistant

0 passed, 8 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

The tool's zero missing-tools count does not mean Ollama was detected: static mode does not inspect tool availability. All lesson statuses remain **written (not run)** and runtime verification remains **UNVERIFIED**.

Packaging completed with the explicitly authorised `python scripts\build_packs.py ollama-101` (ZIP writing only).
Actual captured output:

```text
built ollama-101-phase-1-first-steps.zip (19 files)
built ollama-101-phase-2-building-with-ollama.zip (26 files)
built ollama-101-all.zip (2 phases)
```

Generated files are in `dist/packs/`. Packaging executed no lesson code and changed no runtime verification status.
The final static recheck after adding the recorded validation excerpts also returned 8 static-checked, 0 failed.
Temporary authoring helpers were removed; authored deliverables are limited to the owned track folders, plus the three authorised ZIP artifacts.

## Next work
A human may follow the native OS setup and lesson walkthroughs when runtime execution is separately authorised.
Confirm platform-specific installers, error wording, streaming failure behaviour and resource limits then.
