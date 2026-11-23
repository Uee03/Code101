from collections.abc import Callable


def process_once(seen: set[str], message_id: str, effect: Callable[[], None]) -> bool:
    # TODO 1: return False without running the effect when message_id is already in seen
    # TODO 2: run the effect
    # TODO 3: only AFTER the effect succeeded, add the id to seen and return True
    raise NotImplementedError


if __name__ == "__main__":
    seen: set[str] = set()
    log: list[str] = []
    for message_id in ["a", "b", "a"]:
        ran = process_once(seen, message_id, lambda mid=message_id: log.append(mid))
        print(message_id, "ran" if ran else "skipped")

    def failing() -> None:
        raise ConnectionError("down")

    try:
        process_once(seen, "c", failing)
    except ConnectionError:
        print("c failed, so it is not marked as seen:", "c" not in seen)
    print(log)
