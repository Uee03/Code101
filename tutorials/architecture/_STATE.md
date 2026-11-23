# Architecture: authoring state

Updated: 2026-11-23.
Level: 101-zero-to-hero. Scope: ten lessons, three phases.
Execution status: written (not run).
Static documentation status: verified (static only; not rendered or executed).

| Lesson | Status | Static documentation |
|---|---|---|
| 01 What architecture is and why diagrams | written (not run) | verified (static only) |
| 02 Client, server and the request journey | written (not run) | verified (static only) |
| 03 Layers and responsibilities | written (not run) | verified (static only) |
| 04 Data and storage | written (not run) | verified (static only) |
| 05 Mermaid in depth | written (not run) | verified (static only) |
| 06 The C4 model: context and containers | written (not run) | verified (static only) |
| 07 draw.io: editable diagrams | written (not run) | verified (static only) |
| 08 Architecture decision records | written (not run) | verified (static only) |
| 09 Quality attributes and trade-offs | written (not run) | verified (static only) |
| 10 Project: document a system end to end | written (not run) | verified (static only) |

## Boundaries and honesty
No application or diagram was executed or rendered. No Mermaid parse, XML validator, smoke test, benchmark, Docker command or server was used. All lessons show the exact draft notice and `verified: not yet run`. Expected pictures and scores are derived, not captured execution output.

The verifier skips `.mmd`/`.drawio` suffixes. Markdown companion source listings provide line checking of diagram contents without changing shared scripts. Static checking is not syntax validation or a security/availability claim. Exercise sources are included in full in lessons, but the shared verifier only checks code/ files.

## Decisions to retain
- Sources are diagrams and Markdown decisions, not executable programs.
- The C4 work-planning scope treats Keycloak as an external capability; the operational platform stack can include it under another boundary.
- Current VS Code has built-in Mermaid Markdown rendering; the old Mermaid-preview extension is deprecated. Do not prescribe it as a new required installation.
- Keep TODO practice source separate from finished sources. The final project accepts any small app and offers Community Library as one complete answer.
- Plain labels and explicit relationship text preserve meaning without colour. No artwork or icons are used.

## Delivery
Source-pack build: complete. The owner-authorised command `python scripts\build_packs.py architecture-101` wrote the three phase ZIPs and the all-level ZIP under `dist/packs/`. It packaged sources; it did not build or execute an application.
Remaining execution/render review: not performed by instruction, not a missing-toolchain failure.
No edits requested or made to CONTEXT.md, shared tooling or curriculum.

## Static verification record
Command from the repository root: `python scripts\verify_labs.py --static architecture/101`.
Observed output on 2026-11-23:

```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

The same captured summary is included in each lesson without representing it as application output. All execution statuses remain written (not run).

## Pack-build record
Observed packaging output on 2026-11-23:

```text
built architecture-101-phase-1-thinking-in-systems.zip (22 files)
built architecture-101-phase-2-diagram-toolkit.zip (21 files)
built architecture-101-phase-3-documenting-decisions.zip (35 files)
built architecture-101-all.zip (3 phases)
```
