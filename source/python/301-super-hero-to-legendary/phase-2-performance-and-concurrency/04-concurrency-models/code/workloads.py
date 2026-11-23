import time


def cpu_work(n: int) -> int:
    total = 0
    for i in range(n):
        total += i * i % 7
    return total


def io_work(seconds: float) -> float:
    time.sleep(seconds)
    return seconds
