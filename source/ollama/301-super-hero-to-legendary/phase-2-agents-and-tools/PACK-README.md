# Ollama 301 - Phase 2: agents and tools

**Draft: written (not run).** No Ollama command or program was executed by the author, and no static check was run on this level. Every lesson's front matter says `verified: not yet run`.

## Audience and prerequisites
Finish phase 1. Python 3.12+ (standard library only), native Ollama with `llama3.2:3b` (about 2.0 GB, listed with the `tools` capability, checked 2026-11-23). The unit tests need no model.

## Get and extract
Repository: https://github.com/Uee03/Code101 > **Code > Download ZIP**, then open `Code101-main/source/ollama/301-super-hero-to-legendary/phase-2-agents-and-tools`. Generated archives (not yet built): `dist/packs/ollama-301-phase-2-agents-and-tools.zip`, `ollama-301-all.zip`.

## Lessons
| Lesson | New source | What it adds |
|---|---|---|
| 04 Tool calling | `tools.py`, `agent.py`, tests | Allow-list, schema validation, bounded loop, propose-then-confirm, tool-selection measurement |
| 05 Guardrails and privacy | `guards.py`, `attacks.json`, `red_team.py`, tests | Unforgeable delimiter, output checks, canary, redaction, keyed log fingerprint, expiring debug window |

`ollama_http.py`, `validate.py` and `rag_core.py` are byte-identical copies from earlier lessons.

## Run deliberately, as a learner
`python -m unittest` in each `code` folder first. Then `python agent.py eval` and `ask`, and `python red_team.py --trials 3`. Attack texts are harmless test strings for your own lab only.

## Safety and honesty
A prompt is not a control: the controls are code that validates, limits and checks. Heuristics miss paraphrases by design (attack a5 shows it). Attack success rates are measurements on your model on one day, never guarantees.
