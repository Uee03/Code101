import unittest

from metrics import (
    aggregate,
    contains_all,
    first_relevant_rank,
    hit_rate,
    judge,
    mean_reciprocal_rank,
    score_gap,
)
from rag_core import Hit

HITS = [Hit(1, "a.md", "S", "text", 0.9), Hit(2, "b.md", "", "other", 0.5)]
ENTRY = {"id": "q1", "answerable": True, "gold_sources": ["a.md"], "must_contain": ["25"]}


class RankingMetricTests(unittest.TestCase):
    def test_first_relevant_rank(self):
        self.assertEqual(first_relevant_rank(["a", "b", "c"], {"b"}), 2)
        self.assertIsNone(first_relevant_rank(["a", "b"], {"z"}))

    def test_hit_rate(self):
        ranks = [1, 3, None]
        self.assertAlmostEqual(hit_rate(ranks, 1), 1 / 3)
        self.assertAlmostEqual(hit_rate(ranks, 3), 2 / 3)
        self.assertIsNone(hit_rate([], 3))

    def test_mean_reciprocal_rank(self):
        self.assertAlmostEqual(mean_reciprocal_rank([1, 3, None]), 4 / 9)

    def test_contains_all_ignores_case(self):
        self.assertTrue(contains_all("You get 25 DAYS", ["25", "days"]))
        self.assertFalse(contains_all("You get 25", ["25", "days"]))

    def test_score_gap(self):
        self.assertEqual(score_gap([0.7, 0.8], [0.5, 0.6]), (0.7, 0.6, True))
        self.assertEqual(score_gap([0.55, 0.8], [0.6]), (0.55, 0.6, False))


class JudgeTests(unittest.TestCase):
    def test_a_correct_answer(self):
        result = {"answer": "25 days [1].", "status": "answered", "sources": HITS, "problems": []}
        record = judge(ENTRY, HITS, result)
        self.assertEqual(record["rank"], 1)
        self.assertTrue(record["correct"])

    def test_a_citation_to_the_wrong_source_is_not_correct(self):
        result = {"answer": "25 days [2].", "status": "answered", "sources": HITS, "problems": []}
        record = judge(ENTRY, HITS, result)
        self.assertFalse(record["citation_ok"])
        self.assertFalse(record["correct"])

    def test_unanswerable_questions(self):
        entry = {"id": "q9", "answerable": False}
        refused = {"answer": "x", "status": "refused_by_model", "sources": HITS, "problems": []}
        answered = {"answer": "x [1]", "status": "answered", "sources": HITS, "problems": []}
        self.assertTrue(judge(entry, HITS, refused)["refused"])
        self.assertFalse(judge(entry, HITS, answered)["refused"])


class AggregateTests(unittest.TestCase):
    def test_aggregate(self):
        records = [
            {"answerable": True, "rank": 1, "answered": True, "correct": True, "top_score": 0.9},
            {"answerable": True, "rank": 3, "answered": True, "correct": False, "top_score": 0.7},
            {"answerable": True, "rank": None, "answered": False, "correct": False, "top_score": 0.6},
            {"answerable": False, "refused": True, "top_score": 0.5},
            {"answerable": False, "refused": False, "top_score": 0.65},
        ]
        summary = aggregate(records, ks=(1, 3))
        self.assertEqual(summary["answerable"], 3)
        self.assertEqual(summary["unanswerable"], 2)
        self.assertAlmostEqual(summary["hit_rate"][1], 1 / 3)
        self.assertAlmostEqual(summary["hit_rate"][3], 2 / 3)
        self.assertAlmostEqual(summary["mrr"], 4 / 9)
        self.assertAlmostEqual(summary["correct_rate"], 1 / 3)
        self.assertAlmostEqual(summary["false_refusal_rate"], 1 / 3)
        self.assertAlmostEqual(summary["refusal_rate"], 0.5)
        self.assertEqual(summary["wrongly_answered"], 1)
        self.assertEqual(summary["score_gap"], (0.6, 0.65, False))


if __name__ == "__main__":
    unittest.main()
