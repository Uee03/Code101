from metrics import score_gap


def suggest_threshold(answerable_scores, unanswerable_scores):
    """Return a score threshold halfway between the two groups, or None when they overlap.

    answerable_scores are the best retrieval scores of questions the documents can answer;
    unanswerable_scores are the best scores of questions they cannot answer.
    """
    # TODO 1: call score_gap to get (lowest answerable, highest unanswerable, separable)
    # TODO 2: when the groups are separable, return the midpoint of the two numbers
    # TODO 3: otherwise return None
    return None
