from collections.abc import Iterator
from contextlib import contextmanager


@contextmanager
def marked(events: list[str]) -> Iterator[None]:
    events.append("start")
    # TODO: arrange for "finish" to be appended even when the body raises.
    yield


events: list[str] = []
try:
    with marked(events):
        raise ValueError("exercise failure")
except ValueError:
    pass
assert events == ["start", "finish"]
print(events)
