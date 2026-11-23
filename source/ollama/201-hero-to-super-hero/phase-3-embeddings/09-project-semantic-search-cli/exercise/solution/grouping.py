def group_by_source(rows):
    """rows are (source, section, content, score) tuples, best first.

    Return one row per source: the first (best) one, keeping the original order.
    """
    seen = set()
    best = []
    for row in rows:
        if row[0] in seen:
            continue
        seen.add(row[0])
        best.append(row)
    return best
