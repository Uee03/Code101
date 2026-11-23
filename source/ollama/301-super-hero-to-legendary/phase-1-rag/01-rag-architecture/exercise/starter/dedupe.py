from rag_core import Hit


def dedupe_hits(hits):
    """Return the hits without repeated passages.

    Two hits repeat each other when their content is equal after lower-casing and
    collapsing runs of whitespace. Keep the first one of each group and keep the order.
    """
    # TODO 1: build a helper that turns a hit's content into a comparison key
    # TODO 2: remember the keys you have seen and keep a hit only the first time its key appears
    return []
