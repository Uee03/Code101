import os
import sys
import time
from collections.abc import Callable, Sequence
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor

from workloads import cpu_work, io_work

CPU_JOBS = [2_000_000] * 4
IO_JOBS = [0.5] * 4


def run_serial(fn: Callable, jobs: Sequence) -> list:
    return [fn(job) for job in jobs]


def run_threads(fn: Callable, jobs: Sequence) -> list:
    with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
        return list(pool.map(fn, jobs))


def run_processes(fn: Callable, jobs: Sequence) -> list:
    with ProcessPoolExecutor(max_workers=len(jobs)) as pool:
        return list(pool.map(fn, jobs))


def timed(label: str, runner: Callable, fn: Callable, jobs: Sequence) -> list:
    start = time.perf_counter()
    results = runner(fn, jobs)
    elapsed = time.perf_counter() - start
    print(f"{label:<10}{elapsed:7.2f} s")
    return results


def main(kind: str) -> None:
    if kind not in ("cpu", "io"):
        raise SystemExit("usage: python bench.py cpu|io")
    fn, jobs = (cpu_work, CPU_JOBS) if kind == "cpu" else (io_work, IO_JOBS)
    print(f"{kind} workload, {len(jobs)} jobs, {os.cpu_count()} logical CPUs")
    serial = timed("serial", run_serial, fn, jobs)
    threads = timed("threads", run_threads, fn, jobs)
    processes = timed("processes", run_processes, fn, jobs)
    print("same results:", serial == threads == processes)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "cpu")
