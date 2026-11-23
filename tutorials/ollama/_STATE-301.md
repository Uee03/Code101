# Ollama 301 state

Updated: 2026-11-23. Status of all eight lessons: **written (not run)**. Runtime verification: UNVERIFIED.

| Lesson | Status |
|---|---|
| 301.1.01 RAG architecture | written (not run) |
| 301.1.02 Pipeline with citations | written (not run) |
| 301.1.03 Evaluation | written (not run) |
| 301.2.04 Tool calling | written (not run) |
| 301.2.05 Guardrails and privacy | written (not run) |
| 301.3.06 Serving and scaling | written (not run) |
| 301.3.07 Security and deployment | written (not run) |
| 301.3.08 Capstone RAG service | written (not run) |

## Checks
- **No check of any kind was run on level 301**: neither `verify_labs.py --static ollama/301` nor `build_packs.py`, by user instruction. Text-to-source consistency (every code line shown in its lesson, expected unit-test counts 10, 3, 9, 17, 14, 5, 3, 19) is therefore unconfirmed.

## Not done / pending
- Run `python scripts\verify_labs.py --static ollama/301`, fix any reported lines, then `python scripts\build_packs.py ollama-301` and `ollama-201`.
- Review points: nginx phase behaviour (401 versus 403), `host.docker.internal` on Linux, unit tests that start loopback servers (race-sensitive log test), `semsearch.py` treating `#` lines in code fences as headings (documented), model refusals and citation habits of `llama3.2:3b`.
- No runtime run of any lesson.
