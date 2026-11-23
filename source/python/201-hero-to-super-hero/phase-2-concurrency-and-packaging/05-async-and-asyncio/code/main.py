import asyncio


async def fetch_title(note_id: int) -> str:
    if note_id <= 0:
        raise ValueError("note_id must be positive")
    await asyncio.sleep(0)
    return f"note-{note_id}"


async def load_titles(note_ids: list[int]) -> list[str]:
    async with asyncio.timeout(1):
        async with asyncio.TaskGroup() as group:
            tasks = [group.create_task(fetch_title(note_id)) for note_id in note_ids]
    return [task.result() for task in tasks]


if __name__ == "__main__":
    print(asyncio.run(load_titles([2, 1, 3])))
