import json
import math
import urllib.error
import urllib.request
from pathlib import Path

MODEL = "nomic-embed-text:v1.5"
TOP_K = 3


def embed(texts):
    body = {"model": MODEL, "input": texts, "truncate": False}
    request = urllib.request.Request(
        "http://127.0.0.1:11434/api/embed",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        data = json.load(response)
    vectors = data["embeddings"]
    if not isinstance(vectors, list) or len(vectors) != len(texts):
        raise ValueError("Wrong vector count")
    for vector in vectors:
        if not isinstance(vector, list) or not vector:
            raise ValueError("Empty vector")
        if not all(type(x) in (int, float) and math.isfinite(x) for x in vector):
            raise ValueError("Invalid vector")
    return vectors


def cosine(left, right):
    if not left or len(left) != len(right):
        raise ValueError("Incompatible vectors")
    dot = sum(a * b for a, b in zip(left, right))
    left_length = math.sqrt(sum(a * a for a in left))
    right_length = math.sqrt(sum(b * b for b in right))
    if left_length == 0 or right_length == 0:
        raise ValueError("Zero vector")
    return dot / (left_length * right_length)


def main():
    path = Path(__file__).with_name("sentences.json")
    sentences = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(sentences, list) or len(sentences) != 10:
        raise ValueError("Use exactly ten sentences")
    if not all(isinstance(s, str) and 0 < len(s) <= 300 for s in sentences):
        raise ValueError("Invalid sentence")
    query = input("Search (public or invented text only): ").strip()
    if not query or len(query) > 300:
        print("Use 1 to 300 characters; nothing sent.")
        return
    documents = embed(["search_document: " + s for s in sentences])
    question = embed(["search_query: " + query])[0]
    ranked = [(cosine(question, vector), sentence)
              for sentence, vector in zip(sentences, documents)]
    ranked.sort(key=lambda item: item[0], reverse=True)
    for score, sentence in ranked[:TOP_K]:
        print(f"{score:.3f} | {sentence}")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the embedding model.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection or file access failed; check Ollama and sentences.json.")
    except (ValueError, KeyError, TypeError, AttributeError, OverflowError):
        print("Invalid data or vectors; no ranking accepted.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
