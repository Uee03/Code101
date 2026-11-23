import unittest

from stats import percentile, summarise


class PercentileTests(unittest.TestCase):
    def test_nearest_rank_percentiles(self):
        values = [1, 2, 3, 4, 5]
        self.assertEqual(percentile(values, 50), 3)
        self.assertEqual(percentile(values, 95), 5)
        self.assertEqual(percentile(values, 100), 5)
        self.assertEqual(percentile(values, 0), 1)

    def test_input_order_does_not_matter(self):
        self.assertEqual(percentile([5, 1, 3], 50), 3)

    def test_single_value_and_empty_input(self):
        self.assertEqual(percentile([7], 95), 7)
        self.assertIsNone(percentile([], 50))


class SummariseTests(unittest.TestCase):
    def test_summary_of_a_small_run(self):
        results = [
            {"status": 200, "seconds": 1.0, "tokens": 10},
            {"status": 200, "seconds": 3.0, "tokens": 30},
            {"status": 503, "seconds": 0.1, "tokens": 0},
        ]
        summary = summarise(results, 4.0)
        self.assertEqual(summary["requests"], 3)
        self.assertEqual(summary["ok"], 2)
        self.assertEqual(summary["statuses"], {"200": 2, "503": 1})
        self.assertEqual(summary["p50_s"], 1.0)
        self.assertEqual(summary["p95_s"], 3.0)
        self.assertEqual(summary["max_s"], 3.0)
        self.assertEqual(summary["requests_per_s"], 0.5)
        self.assertEqual(summary["tokens_per_s"], 10.0)

    def test_a_run_with_no_successes(self):
        summary = summarise([{"status": "error", "seconds": 0.5, "tokens": 0}], 1.0)
        self.assertEqual(summary["ok"], 0)
        self.assertIsNone(summary["p50_s"])
        self.assertIsNone(summary["max_s"])
        self.assertEqual(summary["statuses"], {"error": 1})


if __name__ == "__main__":
    unittest.main()
