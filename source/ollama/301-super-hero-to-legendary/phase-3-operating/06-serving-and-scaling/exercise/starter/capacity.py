def serial_capacity(tokens_per_second, answer_tokens, target_seconds):
    """How many answers fit inside target_seconds when the server handles one request at a time?

    Each answer takes answer_tokens / tokens_per_second seconds. Return the whole number of answers
    that finish within target_seconds (the last one in the queue must also finish in time).
    Raise ValueError when tokens_per_second, answer_tokens or target_seconds is not positive.
    """
    # TODO 1: reject non-positive inputs with ValueError
    # TODO 2: compute the seconds one answer needs
    # TODO 3: return how many whole answers fit in target_seconds (round down)
    return 0
