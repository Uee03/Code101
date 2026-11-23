import argparse
import hashlib
import re
from pathlib import Path

from db import connect, to_vector_literal
from ollama_http import post_json, run_cli
from textutil import chunk_words, split_paragraphs

MODEL = "nomic-embed-text:v1.5"
DOC_PREFIX = "search_document: "
QUERY_PREFIX = "search_query: "
ALLOWED_SUFFIXES = {".md", ".txt"}
MAX_FILE_BYTES = 1_000_000
MAX_QUERY_CHARS = 500
BATCH = 16
HEADING = re.compile(r"^#{1,6}\s+(.*\S)\s*$")

SEARCH_SQL = """
SELECT d.source, c.section, c.content, c.embedding <=> %s::vector AS distance
FROM search.chunks AS c
JOIN search.documents AS d ON d.id = c.document_id
WHERE c.embedding_model = %s
ORDER BY c.embedding <=> %s::vector
LIMIT %s
"""


def is_searchable(name):
    return not name.startswith(".") and Path(name).suffix.lower() in ALLOWED_SUFFIXES


def split_sections(text):
    sections = []
    heading = ""
    lines = []

    def flush():
        body = "\n".join(lines).strip()
        if body:
            sections.append((heading, body))

    for line in text.splitlines():
        match = HEADING.match(line)
        if match:
            flush()
            heading = match.group(1).strip()
            lines = []
        else:
            lines.append(line)
    flush()
    return sections


def chunk_document(text, max_chars=800, overlap_words=15):
    chunks = []
    current = ""
    for paragraph in split_paragraphs(text):
        if len(paragraph) > max_chars:
            if current:
                chunks.append(current)
                current = ""
            chunks.extend(chunk_words(paragraph, max_chars, overlap_words))
        elif current and len(current) + 2 + len(paragraph) > max_chars:
            chunks.append(current)
            current = paragraph
        else:
            current = f"{current}\n\n{paragraph}" if current else paragraph
    if current:
        chunks.append(current)
    return chunks


def prepare(text):
    return [(heading, chunk) for heading, body in split_sections(text) for chunk in chunk_document(body)]


def embed_text(heading, chunk):
    return f"{heading}\n{chunk}" if heading else chunk


def embed(texts, prefix):
    vectors = []
    for start in range(0, len(texts), BATCH):
        batch = [prefix + text for text in texts[start:start + BATCH]]
        data = post_json("/api/embed", {"model": MODEL, "input": batch, "truncate": False})
        vectors.extend(data["embeddings"])
    if len(vectors) != len(texts):
        raise ValueError("the server returned a different number of vectors than inputs")
    return vectors


def collect_files(root):
    files = []
    skipped = []
    for path in sorted(root.rglob("*")):
        relative_parts = path.relative_to(root).parts
        if any(part.startswith(".") for part in relative_parts):
            continue
        if not path.is_file() or not is_searchable(path.name):
            continue
        resolved = path.resolve()
        try:
            source = resolved.relative_to(root).as_posix()
        except ValueError:
            skipped.append(f"{path.name}: points outside the folder")
            continue
        if resolved.stat().st_size > MAX_FILE_BYTES:
            skipped.append(f"{source}: larger than {MAX_FILE_BYTES} bytes")
            continue
        files.append((source, resolved))
    return files, skipped


def format_result(rank, score, source, section, content):
    snippet = " ".join(content.split())[:80]
    return f"{rank}. {score:.3f} | {source} | {section or '-'} | {snippet}"


def cmd_ingest(folder, prune):
    root = Path(folder).resolve()
    if not root.is_dir():
        raise SystemExit(f"not a folder: {folder}")
    files, skipped = collect_files(root)
    with connect() as conn:
        known = dict(conn.execute("SELECT source, content_hash FROM search.documents").fetchall())
        work = []
        unchanged = 0
        for source, path in files:
            data = path.read_bytes()
            digest = hashlib.sha256(data).hexdigest()
            if known.get(source) == digest:
                unchanged += 1
                continue
            try:
                text = data.decode("utf-8")
            except UnicodeDecodeError:
                skipped.append(f"{source}: not valid UTF-8")
                continue
            work.append((source, digest, prepare(text)))
        texts = [embed_text(heading, chunk) for _, _, pieces in work for heading, chunk in pieces]
        vectors = embed(texts, DOC_PREFIX) if texts else []
        offset = 0
        for source, digest, pieces in work:
            with conn.transaction():
                row = conn.execute("SELECT id FROM search.documents WHERE source = %s", (source,)).fetchone()
                if row:
                    document_id = row[0]
                    conn.execute(
                        "UPDATE search.documents SET title = %s, content_hash = %s, ingested_at = now() WHERE id = %s",
                        (Path(source).stem, digest, document_id),
                    )
                    conn.execute("DELETE FROM search.chunks WHERE document_id = %s", (document_id,))
                else:
                    document_id = conn.execute(
                        "INSERT INTO search.documents (source, title, content_hash) VALUES (%s, %s, %s) RETURNING id",
                        (source, Path(source).stem, digest),
                    ).fetchone()[0]
                for index, (heading, chunk) in enumerate(pieces):
                    conn.execute(
                        "INSERT INTO search.chunks (document_id, chunk_index, section, content, embedding_model, embedding) "
                        "VALUES (%s, %s, %s, %s, %s, %s::vector)",
                        (document_id, index, heading, chunk, MODEL, to_vector_literal(vectors[offset + index])),
                    )
            offset += len(pieces)
        removed = 0
        if prune:
            if not files:
                raise SystemExit("refusing to prune: no searchable files were found")
            removed = conn.execute(
                "DELETE FROM search.documents WHERE source <> ALL(%s)", ([source for source, _ in files],)
            ).rowcount
    written = sum(len(pieces) for _, _, pieces in work)
    print(f"files: {len(files)} found, {len(work)} ingested, {unchanged} unchanged, {len(skipped)} skipped; chunks written: {written}")
    for message in skipped:
        print(f"skipped {message}")
    if prune:
        print(f"pruned {removed} documents no longer on disk")


def cmd_search(query, limit, min_score):
    query = query.strip()
    if not query or len(query) > MAX_QUERY_CHARS:
        raise SystemExit(f"the query must have 1 to {MAX_QUERY_CHARS} characters")
    literal = to_vector_literal(embed([query], QUERY_PREFIX)[0])
    with connect() as conn:
        rows = conn.execute(SEARCH_SQL, (literal, MODEL, literal, limit)).fetchall()
    shown = 0
    for rank, (source, section, content, distance) in enumerate(rows, start=1):
        score = 1 - distance
        if score >= min_score:
            print(format_result(rank, score, source, section, content))
            shown += 1
    if shown == 0:
        print("no results at or above the minimum score")


def cmd_stats():
    with connect() as conn:
        documents = conn.execute("SELECT count(*) FROM search.documents").fetchone()[0]
        chunks = conn.execute("SELECT count(*) FROM search.chunks").fetchone()[0]
        models = conn.execute(
            "SELECT embedding_model, count(*) FROM search.chunks GROUP BY embedding_model ORDER BY embedding_model"
        ).fetchall()
    print(f"documents: {documents}")
    print(f"chunks: {chunks}")
    for model, count in models:
        print(f"model {model}: {count} chunks")


def cmd_reset(confirmed):
    if not confirmed:
        raise SystemExit("this deletes every document and chunk; repeat with --yes to confirm")
    with connect() as conn:
        conn.execute("TRUNCATE search.documents CASCADE")
    print("all documents and chunks deleted")


def main():
    parser = argparse.ArgumentParser(prog="semsearch", description="Local semantic search over text files.")
    commands = parser.add_subparsers(dest="command", required=True)
    ingest = commands.add_parser("ingest", help="read .md and .txt files from a folder")
    ingest.add_argument("folder")
    ingest.add_argument("--prune", action="store_true", help="delete documents whose file is gone")
    search = commands.add_parser("search", help="find the passages closest in meaning to a query")
    search.add_argument("query")
    search.add_argument("-k", type=int, default=5, help="how many results (1 to 20)")
    search.add_argument("--min-score", type=float, default=0.0, help="hide results below this similarity")
    commands.add_parser("stats", help="count documents and chunks")
    reset = commands.add_parser("reset", help="delete everything that was ingested")
    reset.add_argument("--yes", action="store_true")
    args = parser.parse_args()
    if args.command == "ingest":
        cmd_ingest(args.folder, args.prune)
    elif args.command == "search":
        if not 1 <= args.k <= 20:
            raise SystemExit("-k must be between 1 and 20")
        cmd_search(args.query, args.k, args.min_score)
    elif args.command == "stats":
        cmd_stats()
    else:
        cmd_reset(args.yes)


if __name__ == "__main__":
    run_cli(main)
