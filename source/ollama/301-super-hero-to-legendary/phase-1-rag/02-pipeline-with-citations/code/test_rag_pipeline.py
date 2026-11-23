import unittest

from rag_core import REFUSAL, Hit
from rag_pipeline import render, row_to_hit

HIT = Hit(7, "leave-policy.md", "Annual leave", "Full-time staff receive 25 days.", 0.8123)


class PipelineHelperTests(unittest.TestCase):
    def test_row_to_hit(self):
        self.assertEqual(row_to_hit((7, "a.md", "", "text", 0.5)), Hit(7, "a.md", "", "text", 0.5))

    def test_render_an_answered_result(self):
        result = {"answer": "25 days [1].", "status": "answered", "sources": [HIT], "problems": []}
        expected = "\n".join([
            "Answer: 25 days [1].",
            "Status: answered",
            "[1] leave-policy.md / Annual leave (cited, score 0.812)",
        ])
        self.assertEqual(render(result), expected)

    def test_render_a_failed_result_lists_the_problems(self):
        result = {"answer": REFUSAL, "status": "failed_checks", "sources": [HIT], "problems": ["the answer cites no source"]}
        expected = "\n".join([
            "Answer: I cannot find that in the documents.",
            "Status: failed_checks",
            "[1] leave-policy.md / Annual leave (retrieved, score 0.812)",
            "Checks failed: the answer cites no source",
        ])
        self.assertEqual(render(result), expected)


if __name__ == "__main__":
    unittest.main()
