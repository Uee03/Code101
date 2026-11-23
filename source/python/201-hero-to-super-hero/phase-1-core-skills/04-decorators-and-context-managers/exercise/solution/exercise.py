from collections.abc import Iterator
from contextlib import contextmanager


@contextmanager
def marked(events: list[str]) -> Iterator[None]:
    events.append("start")
    try:
        yield
    finally:
        events.append("finish")


events: list[str] = []
try:
    with marked(events):
        raise ValueError("exercise failure")
except ValueError:
    pass
assert events == ["start", "finish"]
print(events)
