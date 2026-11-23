import unittest

from report import slowest_prompt, spread


class ReportTests(unittest.TestCase):
    def test_spread(self):
        self.assertEqual(spread([2.0, 1.0, 3.0]), (1.0, 3.0))

    def test_slowest_prompt(self):
        rows = [{"prompt_id": "a", "total_s": "1.0"}, {"prompt_id": "b", "total_s": "2.5"}]
        self.assertEqual(slowest_prompt(rows), "b")


if __name__ == "__main__":
    unittest.main()
