import random
import sqlite3
from collections.abc import Callable

import outbox

Handler = Callable[[outbox.Message], None]


def no_jitter(delay: float) -> float:
    return delay


def full_jitter(delay: float) -> float:
    return random.uniform(0, delay)


def run_once(
    connection: sqlite3.Connection,
    handler: Handler,
    now: float,
    max_attempts: int = 3,
    jitter: Callable[[float], float] = no_jitter,
) -> dict[str, int]:
    stats = {"done": 0, "retry": 0, "dead": 0}
    for message in outbox.due_messages(connection, now):
        try:
            handler(message)
        except Exception as error:
            attempts = message.attempts + 1
            if attempts >= max_attempts:
                outbox.mark_dead(connection, message.id, attempts, str(error))
                stats["dead"] += 1
            else:
                delay = jitter(outbox.backoff(attempts))
                outbox.mark_retry(connection, message.id, attempts, now + delay, str(error))
                stats["retry"] += 1
        else:
            outbox.mark_done(connection, message.id)
            stats["done"] += 1
    return stats
