from rag_core import extract_citations


def cited_sources(result):
    """Return (number, hit) pairs for the sources the answer actually cites, in citation order.

    result is the dictionary returned by answer_question. Source numbers start at 1 and refer to
    positions in result["sources"]. Ignore numbers that do not exist.
    """
    pairs = []
    for number in extract_citations(result["answer"]):
        if 1 <= number <= len(result["sources"]):
            pairs.append((number, result["sources"][number - 1]))
    return pairs
