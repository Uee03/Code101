import time
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor


def square(n: int) -> int:
    return n * n


def slow_upper(text: str) -> str:
    time.sleep(0.01)
    return text.upper()


def parallel_map(fn, items, kind: str) -> list:
    # TODO 1: for kind == "io" use a ThreadPoolExecutor
    # TODO 2: for kind == "cpu" use a ProcessPoolExecutor
    # TODO 3: for any other kind raise ValueError(f"unknown kind: {kind}")
    # Return list(pool.map(fn, items)) so the results keep the input order.
    raise NotImplementedError


if __name__ == "__main__":
    print("cpu", parallel_map(square, [1, 2, 3], "cpu"))
    print("io", parallel_map(slow_upper, ["a", "b"], "io"))
    try:
        parallel_map(square, [1], "gpu")
    except ValueError as error:
        print(error)
