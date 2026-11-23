import unittest

from sentences import chunk_sentences


class SentenceTests(unittest.TestCase):
    def test_groups_sentences_up_to_the_limit(self):
        self.assertEqual(chunk_sentences("One. Two. Three.", 10), ["One. Two.", "Three."])

    def test_long_sentence_stays_whole(self):
        self.assertEqual(chunk_sentences("A very long sentence.", 5), ["A very long sentence."])

    def test_empty_text(self):
        self.assertEqual(chunk_sentences("", 10), [])

    def test_question_and_exclamation_marks_end_sentences(self):
        self.assertEqual(chunk_sentences("Really? Yes! Fine.", 8), ["Really?", "Yes!", "Fine."])


if __name__ == "__main__":
    unittest.main()
