"""Exercise 5: the arithmetic of a fixed-window rate limiter (solution).

Run:  python window.py
"""
import math


def decision(window_start, now, count, limit, window):
    """`count` requests were already counted in the window that began at `window_start`; this is one more.

    Return (allowed, remaining, reset_seconds).
    """
    if now - window_start >= window:
        window_start, count = now, 0
    count += 1
    reset = max(1, math.ceil(window - (now - window_start)))
    return count <= limit, max(0, limit - count), reset


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
