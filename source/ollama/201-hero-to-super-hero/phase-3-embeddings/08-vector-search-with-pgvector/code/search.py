import argparse

from db import connect, to_vector_literal
from ollama_http import post_json, run_cli

MODEL = "nomic-embed-text:v1.5"
QUERY_PREFIX = "search_query: "

SEARCH_SQL = """
SELECT d.title, c.content, c.embedding <=> %s::vector AS distance
FROM search.chunks AS c
JOIN search.documents AS d ON d.id = c.document_id
WHERE c.embedding_model = %s
ORDER BY c.embedding <=> %s::vector
LIMIT %s
"""


def embed_query(text):
    body = {"model": MODEL, "input": QUERY_PREFIX + text, "truncate": False}
    return post_json("/api/embed", body)["embeddings"][0]


def search(text, limit):
    literal = to_vector_literal(embed_query(text))
    with connect() as conn:
        return conn.execute(SEARCH_SQL, (literal, MODEL, literal, limit)).fetchall()


def main():
    parser = argparse.ArgumentParser(description="Semantic search over the stored notes.")
    parser.add_argument("query")
    parser.add_argument("-k", type=int, default=3, help="how many results to show")
    args = parser.parse_args()
    if not 1 <= args.k <= 20:
        raise SystemExit("-k must be between 1 and 20")
    for title, content, distance in search(args.query, args.k):
        print(f"{1 - distance:.3f} | {title} | {content[:70]}")


if __name__ == "__main__":
    run_cli(main)
