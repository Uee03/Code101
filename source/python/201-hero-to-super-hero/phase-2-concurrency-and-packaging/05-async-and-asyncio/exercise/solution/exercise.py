import asyncio


async def double(number: int) -> int:
    await asyncio.sleep(0)
    return number * 2


async def doubles(numbers: list[int]) -> list[int]:
    async with asyncio.TaskGroup() as group:
        tasks = [group.create_task(double(number)) for number in numbers]
    return [task.result() for task in tasks]


result = asyncio.run(doubles([3, 1]))
assert result == [6, 2]
print(result)
