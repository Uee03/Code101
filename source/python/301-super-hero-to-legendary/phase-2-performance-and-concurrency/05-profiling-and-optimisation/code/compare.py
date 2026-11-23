import statistics
import time
from collections.abc import Callable

from report import customers_fast, customers_slow, make_rows


def median_ms(fn: Callable, rows: list, repeats: int = 5) -> float:
    samples = []
    for _ in range(repeats):
        start = time.perf_counter()
        fn(rows)
        samples.append((time.perf_counter() - start) * 1000)
    return statistics.median(samples)


def main() -> None:
    rows = make_rows(20_000)
    print("same result:", customers_slow(rows) == customers_fast(rows))
    print(f"slow median: {median_ms(customers_slow, rows):.1f} ms")
    print(f"fast median: {median_ms(customers_fast, rows):.1f} ms")


if __name__ == "__main__":
    main()
