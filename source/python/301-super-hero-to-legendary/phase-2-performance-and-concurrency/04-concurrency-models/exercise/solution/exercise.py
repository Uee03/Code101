import time
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor


def square(n: int) -> int:
    return n * n


def slow_upper(text: str) -> str:
    time.sleep(0.01)
    return text.upper()


def parallel_map(fn, items, kind: str) -> list:
    if kind == "io":
        pool_class = ThreadPoolExecutor
    elif kind == "cpu":
        pool_class = ProcessPoolExecutor
    else:
        raise ValueError(f"unknown kind: {kind}")
    with pool_class() as pool:
        return list(pool.map(fn, items))


if __name__ == "__main__":
    print("cpu", parallel_map(square, [1, 2, 3], "cpu"))
    print("io", parallel_map(slow_upper, ["a", "b"], "io"))
    try:
        parallel_map(square, [1], "gpu")
    except ValueError as error:
        print(error)
