import re


def chunk_sentences(text, max_chars):
    sentences = [part for part in re.split(r"(?<=[.!?])\s+", text.strip()) if part]
    chunks = []
    current = ""
    for sentence in sentences:
        if current and len(current) + 1 + len(sentence) > max_chars:
            chunks.append(current)
            current = sentence
        else:
            current = f"{current} {sentence}".strip()
    if current:
        chunks.append(current)
    return chunks
