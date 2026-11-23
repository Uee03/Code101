import argparse

import semsearch
from db import connect, to_vector_literal
from ollama_http import post_json, run_cli
from rag_core import Hit, Settings, answer_question, extract_citations

GENERATION_MODEL = "llama3.2:3b"
RETRIEVE_K = 6
SETTINGS = Settings(min_score=0.0, max_hits=4, max_context_chars=3000)
MAX_QUESTION_CHARS = 500

RETRIEVE_SQL = """
SELECT c.id, d.source, c.section, c.content, 1 - (c.embedding <=> %s::vector) AS score
FROM search.chunks AS c
JOIN search.documents AS d ON d.id = c.document_id
WHERE c.embedding_model = %s
ORDER BY c.embedding <=> %s::vector
LIMIT %s
"""


def row_to_hit(row):
    chunk_id, source, section, content, score = row
    return Hit(chunk_id, source, section, content, float(score))


def retrieve(question):
    literal = to_vector_literal(semsearch.embed([question], semsearch.QUERY_PREFIX)[0])
    with connect() as conn:
        rows = conn.execute(RETRIEVE_SQL, (literal, semsearch.MODEL, literal, RETRIEVE_K)).fetchall()
    return [row_to_hit(row) for row in rows]


def generate(messages):
    body = {
        "model": GENERATION_MODEL,
        "messages": messages,
        "stream": False,
        "options": {"temperature": 0, "seed": 7, "num_ctx": 4096, "num_predict": 300},
    }
    data = post_json("/api/chat", body, timeout=300)
    if data.get("done_reason") == "length":
        return ""
    return data["message"]["content"]


def render(result):
    lines = [f"Answer: {result['answer']}", f"Status: {result['status']}"]
    cited = set(extract_citations(result["answer"]))
    for number, hit in enumerate(result["sources"], start=1):
        mark = "cited" if number in cited else "retrieved"
        lines.append(f"[{number}] {hit.source} / {hit.section or '-'} ({mark}, score {hit.score:.3f})")
    if result["problems"]:
        lines.append("Checks failed: " + "; ".join(result["problems"]))
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(prog="rag_pipeline", description="Ask questions of ingested documents.")
    commands = parser.add_subparsers(dest="command", required=True)
    ingest = commands.add_parser("ingest", help="read .md and .txt files from a folder")
    ingest.add_argument("folder")
    ingest.add_argument("--prune", action="store_true")
    ask = commands.add_parser("ask", help="answer one question from the documents")
    ask.add_argument("question")
    args = parser.parse_args()
    if args.command == "ingest":
        semsearch.cmd_ingest(args.folder, args.prune)
        return
    question = args.question.strip()
    if not question or len(question) > MAX_QUESTION_CHARS:
        raise SystemExit(f"the question must have 1 to {MAX_QUESTION_CHARS} characters")
    print(render(answer_question(question, retrieve, generate, SETTINGS)))


if __name__ == "__main__":
    run_cli(main)
