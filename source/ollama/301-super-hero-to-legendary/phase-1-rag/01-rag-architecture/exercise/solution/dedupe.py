def dedupe_hits(hits):
    """Return the hits without repeated passages.

    Two hits repeat each other when their content is equal after lower-casing and
    collapsing runs of whitespace. Keep the first one of each group and keep the order.
    """
    seen = set()
    kept = []
    for hit in hits:
        key = " ".join(hit.content.lower().split())
        if key in seen:
            continue
        seen.add(key)
        kept.append(hit)
    return kept
