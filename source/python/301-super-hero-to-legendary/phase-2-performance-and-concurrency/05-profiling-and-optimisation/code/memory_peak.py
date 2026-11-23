import tracemalloc
from collections.abc import Callable


def peak_bytes(fn: Callable[[], int]) -> int:
    tracemalloc.start()
    fn()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    return peak


def with_list() -> int:
    return sum([n * n for n in range(200_000)])


def with_generator() -> int:
    return sum(n * n for n in range(200_000))


if __name__ == "__main__":
    list_peak = peak_bytes(with_list)
    generator_peak = peak_bytes(with_generator)
    print(f"list comprehension peak: {list_peak:,} bytes")
    print(f"generator peak: {generator_peak:,} bytes")
    print("generator peak is smaller:", generator_peak < list_peak)
