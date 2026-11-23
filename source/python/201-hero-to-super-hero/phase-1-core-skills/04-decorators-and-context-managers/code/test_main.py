import unittest

from main import greet, managed_events


class WrapperTests(unittest.TestCase):
    def test_result_and_metadata(self) -> None:
        self.assertEqual(greet("Ada"), "HELLO, ADA")
        self.assertEqual(greet.__name__, "greet")
        self.assertEqual(greet.__doc__, "Return a greeting.")

    def test_normal_cleanup(self) -> None:
        events: list[str] = []
        with managed_events(events):
            events.append("body")
        self.assertEqual(events, ["open", "body", "closed"])

    def test_failure_is_not_swallowed(self) -> None:
        events: list[str] = []
        with self.assertRaises(ValueError):
            with managed_events(events):
                raise ValueError("demo failure")
        self.assertEqual(events, ["open", "closed"])
