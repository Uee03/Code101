import math
import re


def dot(left, right):
    return sum(a * b for a, b in zip(left, right))


def norm(vector):
    return math.sqrt(sum(x * x for x in vector))


def normalise(vector):
    length = norm(vector)
    if length == 0:
        raise ValueError("cannot normalise a zero vector")
    return [x / length for x in vector]


def cosine(left, right):
    if not left or len(left) != len(right):
        raise ValueError("vectors must have the same non-zero length")
    left_length = norm(left)
    right_length = norm(right)
    if left_length == 0 or right_length == 0:
        raise ValueError("cannot compare a zero vector")
    return dot(left, right) / (left_length * right_length)


def cosine_rank(query, vectors):
    scores = [cosine(query, vector) for vector in vectors]
    return sorted(range(len(vectors)), key=lambda index: scores[index], reverse=True)


def chunk_words(text, max_chars, overlap_words=0):
    if max_chars <= 0 or overlap_words < 0:
        raise ValueError("max_chars must be positive and overlap_words must not be negative")
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = start
        length = 0
        while end < len(words) and (end == start or length + 1 + len(words[end]) <= max_chars):
            length += len(words[end]) + (1 if end > start else 0)
            end += 1
        chunks.append(" ".join(words[start:end]))
        if end >= len(words):
            break
        start = max(end - overlap_words, start + 1)
    return chunks


def split_paragraphs(text):
    return [part.strip() for part in re.split(r"\n\s*\n", text) if part.strip()]
