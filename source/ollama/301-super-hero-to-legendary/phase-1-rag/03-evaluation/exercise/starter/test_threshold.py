import unittest

from threshold import suggest_threshold


class ThresholdTests(unittest.TestCase):
    def test_midpoint_when_the_groups_do_not_overlap(self):
        self.assertAlmostEqual(suggest_threshold([0.7, 0.8], [0.5, 0.6]), 0.65)

    def test_none_when_they_overlap(self):
        self.assertIsNone(suggest_threshold([0.55, 0.8], [0.6]))


if __name__ == "__main__":
    unittest.main()
