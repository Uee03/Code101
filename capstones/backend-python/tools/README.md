# Authoring tools

The lesson texts in `../tutorials` are **assembled**, not typed twice: every code block is copied byte for byte from the matching `source/.../code` file, and every "Expected output" block is a real captured output. That is how the lesson text and the source pack stay identical (the verifier checks it).

| File | Purpose |
|------|---------|
| `lessons/NN-slug.tmpl` | the lesson text with markers: `@@FILE path` inserts a code file, `@@FILE_STARTER name` and `@@FILE_EXERCISE name` insert the exercise files, `@@OUT name` inserts `outputs/name.txt` |
| `outputs/*.txt` | outputs captured on 2026-11-23 from the running stacks (Windows 11, Docker 29.9.3); a few lines of a long output are selected with `@@OUT name tail=N` or `head=N` |
| `assemble.py` | `python tools/assemble.py [NN-slug ...]` rewrites `tutorials/<phase>/NN-slug.md` |
| `diff_phases.py` | `python tools/diff_phases.py` lists which files are new, changed or unchanged per phase (unchanged ones go into `skip_lesson_check` of `verify.json`); `python tools/diff_phases.py skips` prints the skip lists as JSON |

After changing code: edit the file in `source`, run `python tools/assemble.py`, then `python scripts/verify_labs.py capstones/backend-python` from the repository root. If a change alters an output, capture it again and replace the file in `outputs/`.
