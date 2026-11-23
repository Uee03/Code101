from metrics import score_gap


def suggest_threshold(answerable_scores, unanswerable_scores):
    """Return a score threshold halfway between the two groups, or None when they overlap.

    answerable_scores are the best retrieval scores of questions the documents can answer;
    unanswerable_scores are the best scores of questions they cannot answer.
    """
    lowest_answerable, highest_unanswerable, separable = score_gap(answerable_scores, unanswerable_scores)
    if not separable:
        return None
    return (lowest_answerable + highest_unanswerable) / 2
