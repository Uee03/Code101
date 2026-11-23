"""Build tutorials/<phase>/<NN-slug>.md from _work/lessons/<NN-slug>.tmpl by inserting code files.

A line `@@FILE relative/path` becomes a caption plus a fenced block with the exact bytes of source/<phase>/<NN>/code/<path>.
A line `@@FILE relative/path first-last` inserts only that 1-based line range (used for long files that are explained in parts).
"""
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
LANG = {".py": "python", ".json": "json", ".toml": "toml", ".yml": "yaml", ".yaml": "yaml", ".sql": "sql", ".txt": "text"}
LESSONS = {
    "01-skeleton": ("phase-1-skeleton", "01-skeleton"),
    "02-data": ("phase-2-data", "02-data"),
    "03-identity": ("phase-3-identity", "03-identity"),
    "04-run-and-ship": ("phase-4-run-and-ship", "04-run-and-ship"),
    "05-hardening": ("phase-5-hardening", "05-hardening"),
}


def language(path: Path) -> str:
    if path.name in ("Dockerfile",):
        return "dockerfile"
    if path.suffix == ".example" or path.name.startswith(".env") or path.name in (".gitignore", ".dockerignore"):
        return "text"
    return LANG.get(path.suffix, "text")


def block(code_dir: Path, spec: str, caption_prefix: str = "") -> str:
    parts = spec.split()
    rel = parts[0]
    path = code_dir / rel
    text = path.read_text(encoding="utf-8")
    if len(parts) > 1:
        first, last = (int(n) for n in parts[1].split("-"))
        lines = text.splitlines()[first - 1:last]
        text = "\n".join(lines) + "\n"
    return f"**File: `{caption_prefix}{rel}`**\n```{language(path)}\n{text.rstrip(chr(10))}\n```"


def output_block(spec: str) -> str:
    parts = spec.split()
    text = (root / "tools" / "outputs" / f"{parts[0]}.txt").read_text(encoding="utf-8").rstrip("\n")
    lines = text.split("\n")
    for option in parts[1:]:
        key, value = option.split("=")
        lines = lines[-int(value):] if key == "tail" else lines[:int(value)]
    return "```text\n" + "\n".join(lines) + "\n```"


def build(name: str) -> None:
    phase, lesson = LESSONS[name]
    lesson_dir = root / "source" / phase / lesson
    code_dir = lesson_dir / "code"
    template = (root / "tools" / "lessons" / f"{name}.tmpl").read_text(encoding="utf-8")
    out = []
    for line in template.split("\n"):
        if line.startswith("@@OUT "):
            out.append(output_block(line[6:].strip()))
        elif line.startswith("@@FILE_EXERCISE "):
            out.append(block(lesson_dir / "exercise" / "solution", line[16:].strip(), "exercise/solution/"))
        elif line.startswith("@@FILE_STARTER "):
            out.append(block(lesson_dir / "exercise" / "starter", line[15:].strip(), "exercise/starter/"))
        elif line.startswith("@@FILE "):
            out.append(block(code_dir, line[7:].strip()))
        else:
            out.append(line)
    target = root / "tutorials" / phase / f"{lesson}.md"
    target.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print("wrote", target.relative_to(root), len(out), "lines")


if __name__ == "__main__":
    for lesson_name in sys.argv[1:] or LESSONS:
        build(lesson_name)
