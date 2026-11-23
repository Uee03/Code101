from collections.abc import Callable, Iterator
from contextlib import contextmanager
from functools import wraps


def uppercase(function: Callable[[str], str]) -> Callable[[str], str]:
    @wraps(function)
    def wrapper(name: str) -> str:
        return function(name).upper()

    return wrapper


@uppercase
def greet(name: str) -> str:
    """Return a greeting."""
    return f"Hello, {name}"


@contextmanager
def managed_events(events: list[str]) -> Iterator[list[str]]:
    events.append("open")
    try:
        yield events
    finally:
        events.append("closed")


if __name__ == "__main__":
    print(greet("Ada"))
    events: list[str] = []
    try:
        with managed_events(events) as active:
            active.append("body")
            raise ValueError("demo failure")
    except ValueError:
        pass
    print(events)
