from enum import Enum


class Decision(Enum):
    EXECUTE = "execute"
    REPLAY = "replay"
    CONFLICT = "conflict"


def decide(stored: dict[str, str], key: str, fingerprint: str) -> Decision:
    if key not in stored:
        return Decision.EXECUTE
    if stored[key] == fingerprint:
        return Decision.REPLAY
    return Decision.CONFLICT


if __name__ == "__main__":
    stored: dict[str, str] = {}
    for key, fingerprint in [("k1", "aaa"), ("k1", "aaa"), ("k1", "bbb"), ("k2", "bbb")]:
        decision = decide(stored, key, fingerprint)
        print(key, fingerprint, decision.value)
        if decision is Decision.EXECUTE:
            stored[key] = fingerprint
