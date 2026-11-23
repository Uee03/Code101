import math


def serial_capacity(tokens_per_second, answer_tokens, target_seconds):
    """How many answers fit inside target_seconds when the server handles one request at a time?

    Each answer takes answer_tokens / tokens_per_second seconds. Return the whole number of answers
    that finish within target_seconds (the last one in the queue must also finish in time).
    Raise ValueError when tokens_per_second, answer_tokens or target_seconds is not positive.
    """
    if tokens_per_second <= 0 or answer_tokens <= 0 or target_seconds <= 0:
        raise ValueError("all three numbers must be positive")
    seconds_per_answer = answer_tokens / tokens_per_second
    return math.floor(target_seconds / seconds_per_answer)
