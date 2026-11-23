import unittest

from cited import cited_sources
from rag_core import Hit

FIRST = Hit(1, "a.md", "One", "text one", 0.9)
SECOND = Hit(2, "b.md", "Two", "text two", 0.8)


class CitedTests(unittest.TestCase):
    def test_only_cited_sources_are_returned(self):
        result = {"answer": "Fact [2].", "sources": [FIRST, SECOND]}
        self.assertEqual(cited_sources(result), [(2, SECOND)])

    def test_unknown_numbers_are_ignored(self):
        result = {"answer": "Fact [1] and [9].", "sources": [FIRST, SECOND]}
        self.assertEqual(cited_sources(result), [(1, FIRST)])

    def test_no_citations(self):
        self.assertEqual(cited_sources({"answer": "No cites.", "sources": [FIRST]}), [])


if __name__ == "__main__":
    unittest.main()
