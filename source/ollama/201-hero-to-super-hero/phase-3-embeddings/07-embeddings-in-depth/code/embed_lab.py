import argparse
import json
from pathlib import Path

from ollama_http import post_json, run_cli
from textutil import chunk_words, cosine, cosine_rank, dot, norm, normalise, split_paragraphs

HERE = Path(__file__).resolve().parent
MODEL = "nomic-embed-text:v1.5"
DOC_PREFIX = "search_document: "
QUERY_PREFIX = "search_query: "
BATCH = 16
STRATEGIES = {
    "paragraphs": split_paragraphs,
    "words 150": lambda text: chunk_words(text, 150, 5),
    "words 400": lambda text: chunk_words(text, 400, 5),
    "words 1500": lambda text: chunk_words(text, 1500, 5),
}


def embed(texts, prefix):
    vectors = []
    for start in range(0, len(texts), BATCH):
        batch = [prefix + text for text in texts[start:start + BATCH]]
        data = post_json("/api/embed", {"model": MODEL, "input": batch, "truncate": False})
        vectors.extend(data["embeddings"])
    if len(vectors) != len(texts):
        raise ValueError("the server returned a different number of vectors than inputs")
    return vectors


def show_norms():
    sentences = [
        "The cat sat on the mat.",
        "A kitten rests on a rug.",
        "Invoices are due in 30 days.",
    ]
    vectors = embed(sentences, DOC_PREFIX)
    print(f"dimensions: {len(vectors[0])}")
    for sentence, vector in zip(sentences, vectors):
        print(f"norm={norm(vector):.4f}  {sentence}")
    for left, right in [(0, 1), (0, 2), (1, 2)]:
        by_cosine = cosine(vectors[left], vectors[right])
        by_dot = dot(normalise(vectors[left]), normalise(vectors[right]))
        print(f"pair {left}-{right}: cosine={by_cosine:.4f} dot_of_unit_vectors={by_dot:.4f}")


def run_experiment():
    text = (HERE / "handbook.txt").read_text(encoding="utf-8")
    questions = json.loads((HERE / "questions.json").read_text(encoding="utf-8"))
    query_vectors = embed([item["question"] for item in questions], QUERY_PREFIX)
    print("strategy | chunks | avg_chars | top1 | top3")
    for name, make_chunks in STRATEGIES.items():
        chunks = make_chunks(text)
        vectors = embed(chunks, DOC_PREFIX)
        top1 = 0
        top3 = 0
        for item, query_vector in zip(questions, query_vectors):
            order = cosine_rank(query_vector, vectors)
            marker = item["marker"].lower()
            if marker in chunks[order[0]].lower():
                top1 += 1
            if any(marker in chunks[index].lower() for index in order[:3]):
                top3 += 1
        average = sum(len(chunk) for chunk in chunks) / len(chunks)
        print(f"{name} | {len(chunks)} | {average:.0f} | {top1}/{len(questions)} | {top3}/{len(questions)}")


def main():
    parser = argparse.ArgumentParser(description="Embedding experiments.")
    parser.add_argument("action", choices=["norms", "chunks"])
    args = parser.parse_args()
    if args.action == "norms":
        show_norms()
    else:
        run_experiment()


if __name__ == "__main__":
    run_cli(main)
