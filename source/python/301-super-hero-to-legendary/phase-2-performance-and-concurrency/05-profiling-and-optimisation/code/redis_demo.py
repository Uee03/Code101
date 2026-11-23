import os
import uuid

from cache import cached_lookup
from redis_store import RedisStore

loads: list[int] = []


def load() -> str:
    loads.append(1)
    return "expensive result"


def main() -> None:
    store = RedisStore(os.environ.get("REDIS_URL", "redis://127.0.0.1:6390/0"))
    key = f"demo:lesson05:{uuid.uuid4()}"
    cached_lookup(store, key, load, ttl_seconds=30)
    print("first call loaded:", len(loads) == 1)
    cached_lookup(store, key, load, ttl_seconds=30)
    print("second call loaded:", len(loads) == 2)


if __name__ == "__main__":
    main()
