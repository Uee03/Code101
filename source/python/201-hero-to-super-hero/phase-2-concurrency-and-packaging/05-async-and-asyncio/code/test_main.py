import asyncio
import unittest

from main import load_titles


class AsyncTests(unittest.IsolatedAsyncioTestCase):
    async def test_result_order(self) -> None:
        self.assertEqual(await load_titles([2, 1]), ["note-2", "note-1"])

    async def test_empty(self) -> None:
        self.assertEqual(await load_titles([]), [])

    async def test_group_failure(self) -> None:
        with self.assertRaises(ExceptionGroup) as caught:
            await load_titles([1, 0])
        self.assertTrue(any(isinstance(error, ValueError) for error in caught.exception.exceptions))

    async def test_cancellation_runs_cleanup(self) -> None:
        entered = asyncio.Event()
        closed: list[bool] = []

        async def worker() -> None:
            try:
                entered.set()
                await asyncio.Event().wait()
            finally:
                closed.append(True)

        task = asyncio.create_task(worker())
        await entered.wait()
        task.cancel()
        with self.assertRaises(asyncio.CancelledError):
            await task
        self.assertEqual(closed, [True])

    async def test_timeout_cancels_wait(self) -> None:
        with self.assertRaises(TimeoutError):
            async with asyncio.timeout(0):
                await asyncio.Event().wait()
