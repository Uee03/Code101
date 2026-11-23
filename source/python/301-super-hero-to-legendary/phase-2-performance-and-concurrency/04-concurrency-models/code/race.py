import threading

THREADS = 4
PER_THREAD = 100_000


def count(use_lock: bool, threads: int = THREADS, per_thread: int = PER_THREAD) -> int:
    counter = 0
    lock = threading.Lock()

    def work() -> None:
        nonlocal counter
        for _ in range(per_thread):
            if use_lock:
                with lock:
                    counter += 1
            else:
                counter += 1

    workers = [threading.Thread(target=work) for _ in range(threads)]
    for worker in workers:
        worker.start()
    for worker in workers:
        worker.join()
    return counter


if __name__ == "__main__":
    expected = THREADS * PER_THREAD
    print("expected:", expected)
    print("with lock:", count(True))
    print("without lock never above expected:", count(False) <= expected)
