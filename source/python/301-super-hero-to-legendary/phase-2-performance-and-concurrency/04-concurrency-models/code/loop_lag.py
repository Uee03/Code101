import asyncio
import time
from collections.abc import Awaitable, Callable


def blocking_call() -> None:
    time.sleep(0.3)


async def ticker(stop: asyncio.Event) -> float:
    worst = 0.0
    last = time.perf_counter()
    while not stop.is_set():
        await asyncio.sleep(0.01)
        now = time.perf_counter()
        worst = max(worst, now - last)
        last = now
    return worst


async def blocks_the_loop() -> None:
    blocking_call()


async def offloaded_to_a_thread() -> None:
    await asyncio.to_thread(blocking_call)


async def measure(label: str, work: Callable[[], Awaitable[None]]) -> None:
    stop = asyncio.Event()
    watcher = asyncio.create_task(ticker(stop))
    await asyncio.sleep(0.05)
    await work()
    stop.set()
    worst = await watcher
    print(f"{label}: loop stalled for more than 0.2 s: {worst > 0.2}")


async def main() -> None:
    await measure("blocking call in a coroutine", blocks_the_loop)
    await measure("asyncio.to_thread", offloaded_to_a_thread)


if __name__ == "__main__":
    asyncio.run(main())
