# Code101

From zero to hero, to super hero, to legendary: tutorials for people from any field who want to become
senior-level developers. Every lesson shows every step, and every level ships an unzippable **source pack**
split into phases.

**Free choice:** learn any track in any order, then apply it in a capstone with any backend and any client (for
example ASP.NET + Flutter or Go + React). Start at [docs/START-HERE.md](docs/START-HERE.md) or the
[capstones](capstones/README.md).

> **Status:** about 380 lessons and nine capstones are written; most are not yet run. Live status:
> [CONTEXT.md](CONTEXT.md). Plan: [docs/PLAN.md](docs/PLAN.md).

## The three levels

| Level | Name | Audience |
|-------|------|----------|
| **101** | Zero to Hero | Never coded before |
| **201** | Hero to Super Hero | Junior to advanced/intermediate developer |
| **301** | Super Hero to Legendary | Intermediate to senior level |

## Tracks

Python, C#, C, C++, Go, Rust, HTML + CSS + TypeScript, Angular, React, Flutter, Kotlin + Jetpack Compose,
Unity, Databases (PostgreSQL), Supabase, Docker, Ollama, System Architecture, Design Patterns + SOLID.
**Capstones** combine them into full-stack, monolith and microservice projects and teach API craft, identity
(Keycloak, Authentik) and security as chapters.

## Source packs

Build the zips with `python scripts/build_packs.py`; they appear in `dist/packs/`:

| Zip | Contains |
|-----|----------|
| `python-101-phase-1-foundations.zip` | one phase: every lesson's finished code, exercise starters and solutions |
| `python-101-all.zip` | every phase of the level |
| `code101-art-assets.zip` | the CC0 icon library (549 icons) for UI lessons |

Check that the code in every lesson runs: `python scripts/verify_labs.py`.

## Documents

| File | Purpose |
|------|---------|
| [CONTEXT.md](CONTEXT.md) | Live state: what is done, what is next, decisions. Read first. |
| [docs/PLAN.md](docs/PLAN.md) | Master plan, decisions, waves, capstones, token rules |
| [docs/CURRICULUM.md](docs/CURRICULUM.md) | Topics per track and level, coverage matrix |
| [docs/AGENTS-SKILLS-PLAN.md](docs/AGENTS-SKILLS-PLAN.md) | Existing vs missing agents/skills |
| [docs/LINKS.md](docs/LINKS.md) | Ranked, pruned source links |
| [docs/RECOMMENDATIONS.md](docs/RECOMMENDATIONS.md) | Ideas to make learning easier |
| [.github/](.github) | Tutorial agents, skills and prompts |
| [assets/art/README.md](assets/art/README.md) | Icons and licenses |

## Layout

```
tutorials/<track>/<level>/phase-<n>-<slug>/NN-slug.md     lesson text
source/<track>/<level>/phase-<n>-<slug>/NN-slug/          code, exercises, verify.json
capstones/                                                full-stack projects
assets/art/                                               icons, loaders, brand marks
scripts/                                                  build_packs.py, verify_labs.py, check_links.py
reviews/                                                  learner walk-through logs
```

## License

MIT for all lesson text and code: see [LICENSE](LICENSE). Art in `assets/art/icons` and `assets/art/loaders` is CC0; see `assets/art/README.md`.
