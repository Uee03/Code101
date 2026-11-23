import unittest

from main import Countdown, clean_titles


class IteratorTests(unittest.TestCase):
    def test_protocol_and_exhaustion(self) -> None:
        counter = Countdown(1)
        self.assertIs(iter(counter), counter)
        self.assertEqual(next(counter), 1)
        with self.assertRaises(StopIteration):
            next(counter)
        self.assertEqual(list(counter), [])

    def test_empty_countdown(self) -> None:
        self.assertEqual(list(Countdown(0)), [])

    def test_filter(self) -> None:
        self.assertEqual(list(clean_titles([" A ", "", "B"])), ["A", "B"])

    def test_lazy_and_single_pass(self) -> None:
        lines = ["A"]
        stream = clean_titles(lines)
        lines.append("B")
        self.assertEqual(list(stream), ["A", "B"])
        self.assertEqual(list(stream), [])
