import hashlib
import json
from pathlib import Path

from db import connect, to_vector_literal
from ollama_http import post_json, run_cli

HERE = Path(__file__).resolve().parent
MODEL = "nomic-embed-text:v1.5"
DOC_PREFIX = "search_document: "


def embed(texts):
    body = {"model": MODEL, "input": [DOC_PREFIX + text for text in texts], "truncate": False}
    vectors = post_json("/api/embed", body)["embeddings"]
    if len(vectors) != len(texts):
        raise ValueError("the server returned a different number of vectors than inputs")
    return vectors


def content_hash(note):
    payload = json.dumps(note, sort_keys=True, ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def ingest(notes):
    with connect() as conn:
        rows = conn.execute("SELECT id, source, content_hash FROM search.documents").fetchall()
        known = {source: (document_id, digest) for document_id, source, digest in rows}
        pending = []
        for note in notes:
            digest = content_hash(note)
            existing = known.get(note["id"])
            if existing and existing[1] == digest:
                continue
            pending.append((note, digest, existing[0] if existing else None))
        vectors = embed([note["text"] for note, _, _ in pending]) if pending else []
        for (note, digest, document_id), vector in zip(pending, vectors):
            with conn.transaction():
                if document_id is None:
                    document_id = conn.execute(
                        "INSERT INTO search.documents (source, title, content_hash) VALUES (%s, %s, %s) RETURNING id",
                        (note["id"], note["title"], digest),
                    ).fetchone()[0]
                else:
                    conn.execute(
                        "UPDATE search.documents SET title = %s, content_hash = %s, ingested_at = now() WHERE id = %s",
                        (note["title"], digest, document_id),
                    )
                    conn.execute("DELETE FROM search.chunks WHERE document_id = %s", (document_id,))
                conn.execute(
                    "INSERT INTO search.chunks (document_id, chunk_index, section, content, embedding_model, embedding) "
                    "VALUES (%s, 0, %s, %s, %s, %s::vector)",
                    (document_id, note["title"], note["text"], MODEL, to_vector_literal(vector)),
                )
    print(f"ingested {len(pending)} notes, skipped {len(notes) - len(pending)} unchanged")


def main():
    notes = json.loads((HERE / "notes.json").read_text(encoding="utf-8"))
    ingest(notes)


if __name__ == "__main__":
    run_cli(main)
