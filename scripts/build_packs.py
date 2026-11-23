#!/usr/bin/env python3
"""Build Code101 source-pack zips into dist/packs/.

Usage:
    python scripts/build_packs.py                  # all packs + art library
    python scripts/build_packs.py python           # only packs whose name contains "python"
    python scripts/build_packs.py --list           # show what would be built

Inputs:   source/<track>/<level>/<phase>/...   and   capstones/<Cxx>/source/<phase>/...
Outputs:  dist/packs/<track>-<level-code>-phase-<n>-<slug>.zip   (one per phase)
          dist/packs/<track>-<level-code>-all.zip                (every phase of a level)
          dist/packs/<capstone>-phase-<n>-<slug>.zip, <capstone>-all.zip
          dist/packs/code101-art-assets.zip                      (whole art library)

Per lesson, art listed in the lesson markdown front matter (assets: [ui/search, ...]) is copied into
<lesson>/assets/ inside the zip, together with the CC0 license.
"""
from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist" / "packs"
ART = ROOT / "assets" / "art"
EXCLUDE = {"node_modules", "bin", "obj", ".venv", "__pycache__", "dist", ".pytest_cache", ".mypy_cache", ".git"}
LEVEL_CODE = {"101-zero-to-hero": "101", "201-hero-to-super-hero": "201", "301-super-hero-to-legendary": "301"}


def files_under(folder: Path):
    for p in sorted(folder.rglob("*")):
        if p.is_file() and not (EXCLUDE & set(p.relative_to(folder).parts)):
            yield p


def front_matter_assets(md: Path) -> list[str]:
    if not md.exists():
        return []
    text = md.read_text(encoding="utf-8")
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    if not m:
        return []
    a = re.search(r"^assets:\s*\[(.*?)\]", m.group(1), re.M)
    return [x.strip() for x in a.group(1).split(",") if x.strip()] if a else []


def lesson_md_for(lesson: Path) -> Path:
    rel = lesson.relative_to(ROOT).parts
    if rel[0] == "source":
        return ROOT / "tutorials" / Path(*rel[1:-1]) / (rel[-1] + ".md")
    i = rel.index("source")
    return ROOT.joinpath(*rel[:i], "tutorials", *rel[i + 1:-1], rel[-1] + ".md")


def add_phase(zf: zipfile.ZipFile, phase: Path, prefix: str) -> int:
    n = 0
    for f in files_under(phase):
        zf.write(f, f"{prefix}/{f.relative_to(phase).as_posix()}")
        n += 1
    uses_art = False
    for lesson in sorted(p for p in phase.iterdir() if p.is_dir()):
        for name in front_matter_assets(lesson_md_for(lesson)):
            icon = ART / "icons" / f"{name}.svg"
            if icon.exists():
                zf.write(icon, f"{prefix}/{lesson.name}/assets/icons/{name}.svg")
                uses_art = True
            else:
                print(f"  WARNING: art not found: {name} (lesson {lesson.name})")
    if uses_art:
        zf.write(ART / "LICENSE-ICONS-CC0.txt", f"{prefix}/LICENSE-ICONS-CC0.txt")
    return n


def slug_parts(phase_name: str) -> tuple[str, str]:
    m = re.match(r"phase-(\d+)-(.+)", phase_name)
    return (m.group(1), m.group(2)) if m else ("0", phase_name)


def collect() -> list[tuple[str, str, Path]]:
    """Return (group_name, phase_zip_name, phase_dir) for every phase."""
    out: list[tuple[str, str, Path]] = []
    src = ROOT / "source"
    if src.exists():
        for track in sorted(p for p in src.iterdir() if p.is_dir()):
            for level in sorted(p for p in track.iterdir() if p.is_dir()):
                code = LEVEL_CODE.get(level.name, level.name)
                for phase in sorted(p for p in level.iterdir() if p.is_dir()):
                    n, slug = slug_parts(phase.name)
                    out.append((f"{track.name}-{code}", f"{track.name}-{code}-phase-{n}-{slug}", phase))
    caps = ROOT / "capstones"
    if caps.exists():
        for cap in sorted(p for p in caps.iterdir() if p.is_dir() and (p / "source").exists()):
            for phase in sorted(p for p in (cap / "source").iterdir() if p.is_dir()):
                n, slug = slug_parts(phase.name)
                out.append((cap.name, f"{cap.name}-phase-{n}-{slug}", phase))
    return out


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    list_only = "--list" in sys.argv
    phases = [p for p in collect() if not args or any(a in p[1] for a in args)]
    if not list_only:
        DIST.mkdir(parents=True, exist_ok=True)
    groups: dict[str, list[tuple[str, Path]]] = {}
    for group, zname, phase in phases:
        groups.setdefault(group, []).append((zname, phase))
        if not (phase / "PACK-README.md").exists():
            print(f"  WARNING: {phase.relative_to(ROOT).as_posix()} has no PACK-README.md")
        if list_only:
            print(zname)
            continue
        with zipfile.ZipFile(DIST / f"{zname}.zip", "w", zipfile.ZIP_DEFLATED) as zf:
            n = add_phase(zf, phase, zname)
        print(f"built {zname}.zip ({n} files)")
    if not list_only:
        for group, items in groups.items():
            with zipfile.ZipFile(DIST / f"{group}-all.zip", "w", zipfile.ZIP_DEFLATED) as zf:
                for zname, phase in items:
                    add_phase(zf, phase, f"{group}/{zname}")
            print(f"built {group}-all.zip ({len(items)} phases)")
        if not args and ART.exists():
            with zipfile.ZipFile(DIST / "code101-art-assets.zip", "w", zipfile.ZIP_DEFLATED) as zf:
                for f in files_under(ART):
                    zf.write(f, f"code101-art-assets/{f.relative_to(ART).as_posix()}")
            print("built code101-art-assets.zip")
    return 0


if __name__ == "__main__":
    sys.exit(main())
