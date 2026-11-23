import unittest

from compare import cell, median, passes, summarise


class CompareTests(unittest.TestCase):
    def test_passes_requires_every_fragment(self):
        self.assertTrue(passes("1, 2, 3, 4, 5", ["1", "5"]))
        self.assertFalse(passes("1, 2, 3", ["1", "5"]))

    def test_passes_ignores_case(self):
        self.assertTrue(passes("The capital is PARIS.", ["paris"]))

    def test_median_skips_missing_values(self):
        self.assertEqual(median([1.0, None, 3.0]), 2.0)

    def test_median_of_nothing_is_none(self):
        self.assertIsNone(median([None, None]))

    def test_cell_formats(self):
        self.assertEqual(cell(None), "n/a")
        self.assertEqual(cell(1.234), "1.23")
        self.assertEqual(cell(0.5, percent=True), "50%")

    def test_summarise_one_model(self):
        rows = [
            {"model": "m", "total_s": 1.0, "first_token_s": 0.5, "tokens_per_s": 10.0, "passed": True, "gpu_share": 1.0},
            {"model": "m", "total_s": 3.0, "first_token_s": None, "tokens_per_s": 30.0, "passed": False, "gpu_share": 1.0},
        ]
        table = summarise(["m"], rows, {"m": 4.0})
        self.assertEqual(len(table), 1)
        self.assertEqual(table[0]["total_s"], 2.0)
        self.assertEqual(table[0]["first_token_s"], 0.5)
        self.assertEqual(table[0]["tokens_per_s"], 20.0)
        self.assertEqual(table[0]["pass_rate"], 0.5)
        self.assertEqual(table[0]["cold_start_s"], 4.0)


if __name__ == "__main__":
    unittest.main()
