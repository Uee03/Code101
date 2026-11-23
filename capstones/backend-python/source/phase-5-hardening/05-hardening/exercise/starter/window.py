"""Exercise 5: the arithmetic of a fixed-window rate limiter.

Finish decision(). Run:  python window.py
"""
import math


def decision(window_start, now, count, limit, window):
    """`count` requests were already counted in the window that began at `window_start`; this is one more.

    Return (allowed, remaining, reset_seconds).
    """
    # TODO 1: when now - window_start >= window, a new window begins: window_start = now and count = 0
    # TODO 2: count this request (count + 1)
    # TODO 3: allowed is count <= limit; remaining is limit - count but never below 0;
    #         reset_seconds is the time left in the window, rounded UP (math.ceil), at least 1
    raise NotImplementedError


if __name__ == "__main__":
    cases = [
        ("first request:", 0, 0, 0, 100, 60),
        ("last allowed:", 0, 30, 99, 100, 60),
        ("over the limit:", 0, 30, 100, 100, 60),
        ("new window:", 0, 61, 100, 100, 60),
    ]
    for name, start, now, count, limit, window in cases:
        allowed, remaining, reset = decision(start, now, count, limit, window)
        print(f"{name:<16} allowed={allowed} remaining={remaining} reset={reset}")
