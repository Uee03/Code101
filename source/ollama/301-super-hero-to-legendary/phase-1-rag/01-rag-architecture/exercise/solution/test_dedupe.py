import unittest

from dedupe import dedupe_hits
from rag_core import Hit


class DedupeTests(unittest.TestCase):
    def test_repeats_are_dropped_and_order_is_kept(self):
        hits = [
            Hit(1, "a.md", "", "Pay within 30 days.", 0.9),
            Hit(2, "b.md", "", "Other text", 0.8),
            Hit(3, "c.md", "", "  pay   WITHIN 30 days. ", 0.7),
        ]
        self.assertEqual([hit.chunk_id for hit in dedupe_hits(hits)], [1, 2])

    def test_empty_input(self):
        self.assertEqual(dedupe_hits([]), [])


if __name__ == "__main__":
    unittest.main()
