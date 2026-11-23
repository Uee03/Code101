from rag_core import extract_citations


def cited_sources(result):
    """Return (number, hit) pairs for the sources the answer actually cites, in citation order.

    result is the dictionary returned by answer_question. Source numbers start at 1 and refer to
    positions in result["sources"]. Ignore numbers that do not exist.
    """
    # TODO 1: get the cited numbers with extract_citations(result["answer"])
    # TODO 2: for each cited number that is between 1 and len(result["sources"]), pair it with its hit
    return []
