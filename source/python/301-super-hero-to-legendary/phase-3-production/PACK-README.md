# Python 301 - Phase 3: Production

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Three lessons, about 305 minutes including configuration and the review exercise. Prerequisite: phases 1 and 2, Python 3.14 or newer, and Docker with Compose v2 for the container steps. Full lessons: https://github.com/Uee03/Code101/tree/main/tutorials/python/301-super-hero-to-legendary/phase-3-production . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md . No art is used.

Extract first: Windows **Extract All > Extract**, macOS double-click, Linux archive-manager **Extract**. Open the extracted `python-301-phase-3-production` folder. Commands state their starting folder; Windows uses `py -3.14`, macOS and Linux `python3.14`. Work in a copy.

| Lesson | Focus | Time |
|---|---|---|
| 07 Observability | JSON logs with trace ids, OpenTelemetry spans and metrics, full Collector configuration | 100 min |
| 08 Security hardening | dependency audit, secrets, strict validation, ownership checks, SSRF guard, OWASP API Top 10 | 95 min |
| 09 Packaging, release and readiness | wheel, SBOM, multi-stage non-root image, hardened Compose, CI outline, review exercise | 110 min |

## Each lesson uses its own virtual environment
**PowerShell** (example for lesson 07; lessons 08 and 09 are analogous, see each lesson)
```powershell
Set-Location ./07-observability/code
py -3.14 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements.txt
& ./.venv/Scripts/python.exe demo.py
& ./.venv/Scripts/python.exe -m unittest -v
```
**macOS/Linux**
```bash
cd 07-observability/code
python3.14 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python demo.py
.venv/bin/python -m unittest -v
```
Lesson 07's Collector step uses `docker compose up -d` on host ports 4317 and 4318 (loopback only) and the service listens on `127.0.0.1:8000`. Lesson 08 installs `requirements-dev.txt` to get `pip-audit`. Lesson 09 installs the project with `pip install -e ".[dev]"`, runs `python -m unittest discover -s tests` and publishes the container on `127.0.0.1:8100`. No configuration file contains a real secret; lesson 08 creates none, and lesson 09's candidate uses a placeholder path for a secret file that you would create yourself.

Pins are direct teaching snapshots: no lock file is shipped. Resolve a lock (`uv lock` or `pip-compile --generate-hashes`), review it, and audit it before deployment. OpenTelemetry instrumentation packages are beta releases.

## Exercises and phase review
Copy the chosen `exercise/starter` folder itself and rename the copy `try07`, `try08` or `try09` (for lesson 09, inside the lesson folder so `readiness_check.py` sits next to it). Answers are in `exercise/solution`. The final review of the level is the lesson 09 exercise: the production readiness review of a flawed candidate. Afterwards apply the checklist to the [backend-python capstone](https://github.com/Uee03/Code101/tree/main/capstones/backend-python).
