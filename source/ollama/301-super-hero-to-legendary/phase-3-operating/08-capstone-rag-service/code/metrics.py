import statistics

from rag_core import extract_citations

REFUSAL_STATUSES = {"no_evidence", "refused_by_model", "failed_checks", "context_too_small"}


def first_relevant_rank(sources, gold_sources):
    for rank, source in enumerate(sources, start=1):
        if source in gold_sources:
            return rank
    return None


def hit_rate(ranks, k):
    if not ranks:
        return None
    return sum(1 for rank in ranks if rank is not None and rank <= k) / len(ranks)


def mean_reciprocal_rank(ranks):
    if not ranks:
        return None
    return sum(1 / rank for rank in ranks if rank is not None) / len(ranks)


def contains_all(text, fragments):
    lowered = text.lower()
    return all(fragment.lower() in lowered for fragment in fragments)


def rate(count, total):
    return None if total == 0 else count / total


def score_gap(answerable_scores, unanswerable_scores):
    lowest_answerable = min(answerable_scores)
    highest_unanswerable = max(unanswerable_scores)
    return lowest_answerable, highest_unanswerable, lowest_answerable > highest_unanswerable


def judge(entry, hits, result):
    record = {
        "id": entry["id"],
        "answerable": entry["answerable"],
        "status": result["status"],
        "top_score": hits[0].score if hits else None,
    }
    if entry["answerable"]:
        record["rank"] = first_relevant_rank([hit.source for hit in hits], entry["gold_sources"])
        cited = [result["sources"][number - 1].source
                 for number in extract_citations(result["answer"])
                 if 1 <= number <= len(result["sources"])]
        record["answered"] = result["status"] == "answered"
        record["text_ok"] = contains_all(result["answer"], entry["must_contain"])
        record["citation_ok"] = any(source in entry["gold_sources"] for source in cited)
        record["correct"] = record["answered"] and record["text_ok"] and record["citation_ok"]
    else:
        record["refused"] = result["status"] in REFUSAL_STATUSES
    return record


def aggregate(records, ks=(1, 3)):
    answerable = [record for record in records if record["answerable"]]
    unanswerable = [record for record in records if not record["answerable"]]
    ranks = [record["rank"] for record in answerable]
    summary = {
        "answerable": len(answerable),
        "unanswerable": len(unanswerable),
        "hit_rate": {k: hit_rate(ranks, k) for k in ks},
        "mrr": mean_reciprocal_rank(ranks),
        "correct_rate": rate(sum(1 for record in answerable if record["correct"]), len(answerable)),
        "false_refusal_rate": rate(sum(1 for record in answerable if not record["answered"]), len(answerable)),
        "refusal_rate": rate(sum(1 for record in unanswerable if record["refused"]), len(unanswerable)),
        "wrongly_answered": sum(1 for record in unanswerable if not record["refused"]),
        "score_gap": None,
    }
    answerable_scores = [record["top_score"] for record in answerable if record["top_score"] is not None]
    unanswerable_scores = [record["top_score"] for record in unanswerable if record["top_score"] is not None]
    if answerable_scores and unanswerable_scores:
        summary["score_gap"] = score_gap(answerable_scores, unanswerable_scores)
    return summary


def spread(values):
    values = [value for value in values if value is not None]
    if not values:
        return None
    return min(values), statistics.median(values), max(values)
