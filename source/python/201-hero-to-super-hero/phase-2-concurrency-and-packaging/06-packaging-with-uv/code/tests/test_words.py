import unittest

from note_words import count_words


class WordTests(unittest.TestCase):
    def test_whitespace(self) -> None:
        self.assertEqual(count_words(" Read\tthe\ndocs "), 3)

    def test_empty(self) -> None:
        self.assertEqual(count_words(""), 0)
