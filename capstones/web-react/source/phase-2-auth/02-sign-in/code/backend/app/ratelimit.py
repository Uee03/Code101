import math
import threading
import time
from collections.abc import Callable
from dataclasses import dataclass


@dataclass(frozen=True)
class Decision:
    allowed: bool
    limit: int
    remaining: int
    reset_seconds: int

    def headers(self) -> dict[str, str]:
        return {
            "RateLimit-Limit": str(self.limit),
            "RateLimit-Remaining": str(self.remaining),
            "RateLimit-Reset": str(self.reset_seconds),
        }


class FixedWindowLimiter:
    """Counts requests per key in fixed windows. It lives in this process, so with several workers or
    containers each one counts on its own; use a shared store (for example Redis) when that is not acceptable."""

    def __init__(self, window_seconds: int, clock: Callable[[], float] = time.monotonic) -> None:
        self.window = window_seconds
        self.clock = clock
        self._windows: dict[str, tuple[float, int]] = {}  # key -> (window start, requests so far)
        self._lock = threading.Lock()

    def hit(self, key: str, limit: int) -> Decision:
        now = self.clock()
        with self._lock:
            if len(self._windows) > 10_000:  # keep memory bounded: forget windows that already ended
                self._windows = {k: v for k, v in self._windows.items() if now - v[0] < self.window}
            start, count = self._windows.get(key, (now, 0))
            if now - start >= self.window:
                start, count = now, 0
            count += 1
            self._windows[key] = (start, count)
        reset = max(1, math.ceil(self.window - (now - start)))
        return Decision(count <= limit, limit, max(0, limit - count), reset)
