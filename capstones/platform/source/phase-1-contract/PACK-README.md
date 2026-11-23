# Platform, phase 1: Contract

The OpenAPI 3.1 contract for the Tasks and Teams API and a checker that proves it is valid. Status: **verified** on 2026-11-23 (the checker prints `OpenAPI 3.1.1 valid: 27 operations, 33 schemas`, and the exercise solution prints the per-tag counts).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `01-openapi-contract` | The OpenAPI contract | `openapi.yaml` read and validated; you know every endpoint, DTO, error and header of the platform |

## Prerequisites and extraction
- Python 3.10 or newer (author run: 3.15.2). No Docker in this phase.
- Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip platform-phase-1-contract.zip`. Open `01-openapi-contract/code`; keep the `exercise` folder beside it.
- Read the [capstone README](../../README.md) and the [TDD](../../TDD.md) first.

## Run
**Terminal (PowerShell; folder: `01-openapi-contract/code`)**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python scripts/check_openapi.py
```
On macOS and Linux use `python3 -m venv .venv`, `source .venv/bin/activate`, `pip install -r requirements.txt`, `python3 scripts/check_openapi.py`.

## Exercise
`exercise/starter/count_by_tag.py` counts operations per tag; the solution is next to it. Run it with `python count_by_tag.py ../code/openapi.yaml` from the folder that holds the script, while the virtual environment is active.

## For maintainers
`verify.json` installs the two packages into a throwaway `.deps` folder inside a temporary copy (no change to your Python), runs the checker once and runs the exercise solution. `code/openapi.yaml` is listed in `skip_lesson_check` because the lesson shows its important parts, not all 1,200 lines. No Docker, no art. Every later phase pack contains the same `openapi.yaml`.
