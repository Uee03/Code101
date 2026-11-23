import unittest

from grouping import group_by_source


class GroupingTests(unittest.TestCase):
    def test_keeps_the_best_row_per_source_in_order(self):
        rows = [
            ("a.md", "One", "text", 0.9),
            ("b.md", "Two", "text", 0.8),
            ("a.md", "Three", "text", 0.7),
        ]
        self.assertEqual(group_by_source(rows), [rows[0], rows[1]])

    def test_empty_input(self):
        self.assertEqual(group_by_source([]), [])


if __name__ == "__main__":
    unittest.main()
