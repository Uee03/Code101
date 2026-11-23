from enum import Enum


class Decision(Enum):
    EXECUTE = "execute"
    REPLAY = "replay"
    CONFLICT = "conflict"


def decide(stored: dict[str, str], key: str, fingerprint: str) -> Decision:
    # TODO 1: a key we have never seen means EXECUTE
    # TODO 2: a known key with the same fingerprint means REPLAY
    # TODO 3: a known key with a different fingerprint means CONFLICT
    raise NotImplementedError


if __name__ == "__main__":
    stored: dict[str, str] = {}
    for key, fingerprint in [("k1", "aaa"), ("k1", "aaa"), ("k1", "bbb"), ("k2", "bbb")]:
        decision = decide(stored, key, fingerprint)
        print(key, fingerprint, decision.value)
        if decision is Decision.EXECUTE:
            stored[key] = fingerprint
