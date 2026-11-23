import unittest

from rag_core import (
    REFUSAL,
    Hit,
    Settings,
    answer_question,
    build_context,
    build_messages,
    check_answer,
    select_hits,
)

HITS = [
    Hit(1, "a.md", "Intro", "Alpha text", 0.9),
    Hit(2, "b.md", "", "Beta text", 0.7),
    Hit(3, "c.md", "Tail", "Gamma text", 0.2),
]


def forbidden_generate(messages):
    raise AssertionError("the model must not be called without evidence")


class RetrievalTests(unittest.TestCase):
    def test_select_hits_filters_sorts_and_caps(self):
        shuffled = [HITS[2], HITS[0], HITS[1]]
        self.assertEqual([hit.chunk_id for hit in select_hits(shuffled, 0.5, 5)], [1, 2])
        self.assertEqual([hit.chunk_id for hit in select_hits(shuffled, 0.5, 1)], [1])

    def test_build_context_numbers_the_sources(self):
        text, used = build_context(HITS[:2], 1000)
        self.assertEqual(text, "[1] a.md / Intro\nAlpha text\n\n[2] b.md / no section\nBeta text")
        self.assertEqual(used, 2)

    def test_build_context_respects_the_budget(self):
        text, used = build_context(HITS, 30)
        self.assertEqual(text, "[1] a.md / Intro\nAlpha text")
        self.assertEqual(used, 1)


class AnswerCheckTests(unittest.TestCase):
    def test_check_answer(self):
        self.assertEqual(check_answer("Alpha is first [1].", 2), [])
        self.assertEqual(check_answer("Alpha is first.", 2), ["the answer cites no source"])
        self.assertEqual(check_answer("Gamma [3].", 2), ["citation [3] does not exist (only 2 sources)"])
        self.assertEqual(check_answer(REFUSAL, 2), [])
        self.assertEqual(check_answer("  ", 2), ["the answer is empty"])


class PipelineTests(unittest.TestCase):
    def test_no_evidence_means_no_model_call(self):
        result = answer_question("Anything?", lambda question: [], forbidden_generate)
        self.assertEqual(result["status"], "no_evidence")
        self.assertEqual(result["answer"], REFUSAL)

    def test_answered(self):
        settings = Settings(min_score=0.5)
        result = answer_question("Which is first?", lambda question: HITS, lambda messages: "Alpha comes first [1].", settings)
        self.assertEqual(result["status"], "answered")
        self.assertEqual(len(result["sources"]), 2)

    def test_a_citation_that_does_not_exist_fails_the_checks(self):
        settings = Settings(min_score=0.5)
        result = answer_question("Which?", lambda question: HITS, lambda messages: "Gamma [3].", settings)
        self.assertEqual(result["status"], "failed_checks")
        self.assertEqual(result["answer"], REFUSAL)
        self.assertEqual(result["problems"], ["citation [3] does not exist (only 2 sources)"])

    def test_model_refusal_is_reported(self):
        result = answer_question("Which?", lambda question: HITS, lambda messages: REFUSAL, Settings(min_score=0.5))
        self.assertEqual(result["status"], "refused_by_model")

    def test_sources_travel_in_the_user_message(self):
        seen = []

        def generate(messages):
            seen.extend(messages)
            return "Alpha [1]."

        answer_question("What?", lambda question: HITS, generate, Settings(min_score=0.5))
        self.assertNotIn("Alpha text", seen[0]["content"])
        self.assertIn("Alpha text", seen[1]["content"])
        self.assertTrue(seen[1]["content"].endswith("Question: What?"))

    def test_system_extra_is_appended(self):
        messages = build_messages("q", "BLOCK", "Extra rule.")
        self.assertTrue(messages[0]["content"].endswith("Extra rule."))


if __name__ == "__main__":
    unittest.main()
