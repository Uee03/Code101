from collections.abc import Callable


def process_once(seen: set[str], message_id: str, effect: Callable[[], None]) -> bool:
    if message_id in seen:
        return False
    effect()
    seen.add(message_id)
    return True


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
