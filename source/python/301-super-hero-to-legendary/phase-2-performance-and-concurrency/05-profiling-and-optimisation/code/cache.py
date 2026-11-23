from collections.abc import Callable
from functools import lru_cache
from typing import Protocol

RATES = {"EU": 0.21, "US": 0.07}
CALLS = {"tax_rate": 0}


@lru_cache(maxsize=128)
def tax_rate(region: str) -> float:
    CALLS["tax_rate"] += 1
    return RATES[region]


class KeyValueStore(Protocol):
    def get(self, key: str) -> str | None: ...

    def set(self, key: str, value: str, ttl_seconds: int) -> None: ...


class InMemoryStore:
    def __init__(self, clock: Callable[[], float]) -> None:
        self._clock = clock
        self._data: dict[str, tuple[str, float]] = {}

    def get(self, key: str) -> str | None:
        entry = self._data.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if self._clock() >= expires_at:
            del self._data[key]
            return None
        return value

    def set(self, key: str, value: str, ttl_seconds: int) -> None:
        self._data[key] = (value, self._clock() + ttl_seconds)


def cached_lookup(
    store: KeyValueStore, key: str, load: Callable[[], str], ttl_seconds: int = 60
) -> str:
    cached = store.get(key)
    if cached is not None:
        return cached
    value = load()
    store.set(key, value, ttl_seconds)
    return value


def demo() -> None:
    for region in ["EU", "US", "EU", "EU"]:
        tax_rate(region)
    print(tax_rate.cache_info())
    print("underlying calls:", CALLS["tax_rate"])

    now = [0.0]
    store = InMemoryStore(lambda: now[0])
    loads: list[int] = []

    def load() -> str:
        loads.append(1)
        return "42"

    cached_lookup(store, "answer", load)
    cached_lookup(store, "answer", load)
    now[0] = 61.0
    cached_lookup(store, "answer", load)
    print("loads:", len(loads))


if __name__ == "__main__":
    demo()
