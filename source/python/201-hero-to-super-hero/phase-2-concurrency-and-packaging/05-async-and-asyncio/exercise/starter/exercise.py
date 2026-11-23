import asyncio


async def double(number: int) -> int:
    await asyncio.sleep(0)
    return number * 2


async def doubles(numbers: list[int]) -> list[int]:
    # TODO: schedule all double calls in one TaskGroup; preserve input order.
    return []


result = asyncio.run(doubles([3, 1]))
assert result == [6, 2]
print(result)
