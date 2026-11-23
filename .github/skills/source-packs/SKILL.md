---
name: source-packs
description: 'Defines how Code101 source packs are organised, split into phases, zipped, and shipped with art assets. Use when creating or restructuring a source folder, writing a PACK-README, building zips with scripts/build_packs.py, or deciding how code is delivered to learners.'
---

# Source packs

**Best model:** Quick tier for packaging, Act tier when the pack needs code changes.

A **source pack** is an unzippable folder with all code for one level of one track. Every level of
every track and every capstone has one, **split into phases** so a learner downloads only what they are
doing now.

## Layout

```
source/<track>/<level-folder>/<phase-folder>/
  PACK-README.md          what the phase covers, prerequisites, how to run, lesson list
  <NN-slug>/              one folder per lesson
    code/  exercise/starter/  exercise/solution/  verify.json  assets/
tutorials/<track>/<level-folder>/<phase-folder>/NN-slug.md      the matching lesson text
```

Level folders: `101-zero-to-hero`, `201-hero-to-super-hero`, `301-super-hero-to-legendary`.
Phase folders: `phase-<n>-<slug>`, 3 to 5 phases per level, 3 to 4 lessons each.

| Level | Typical phases |
|-------|----------------|
| 101 | 1 Foundations, 2 Building blocks, 3 Real programs (ends with a project) |
| 201 | 1 Core skills, 2 Data and APIs, 3 Quality and testing, 4 Mini full-stack |
| 301 | 1 Architecture, 2 Scale and resilience, 3 Security and operations, 4 Production capstone |

Capstones: `capstones/Cxx-name/{README.md, tutorials/, source/phase-<n>-<slug>/}`, same rules. Each
capstone phase pack contains the **full project at the end of that phase**, so a learner can start at
any phase.

## Zips (built, never committed)

`python scripts/build_packs.py` writes to `dist/packs/`:

| Zip | Contains |
|-----|----------|
| `<track>-<level>-phase-<n>-<slug>.zip` | one phase: lesson folders, `PACK-README.md`, art used, licenses |
| `<track>-<level>-all.zip` | all phases of the level |
| `code101-art-assets.zip` | the complete `assets/art` library |

The script excludes `node_modules`, `bin`, `obj`, `.venv`, `__pycache__`, `dist`, and copies only the art
listed in each lesson's front matter (`assets:`) into that lesson's `assets/` folder inside the zip.

## Rules

1. The lesson text and `code/` must match exactly. Edit the file, then paste into the lesson.
2. No secrets, tokens or real keys. Use `.env.example`.
3. Pin versions in a lockfile or manifest (`requirements.txt`, `*.csproj`, `package.json` + lock, `pubspec.lock`).
4. Every lesson folder has a `verify.json`; the phase passes only if all its lessons pass `verify_labs.py`.
5. Art: use `assets/art` only. Keep `LICENSE-ICONS-CC0.txt` in packs that use icons. Never add the Art repo's proprietary animated, moon, weather-animation, particle or loader-pack files.
6. Keep each phase zip under 25 MB.
