import unittest

from semsearch import chunk_document, format_result, is_searchable, split_sections


class SectionTests(unittest.TestCase):
    def test_split_sections(self):
        text = "Intro line\n# A\ntext a\n\n## B\ntext b\n"
        self.assertEqual(split_sections(text), [("", "Intro line"), ("A", "text a"), ("B", "text b")])

    def test_heading_without_body_is_dropped(self):
        self.assertEqual(split_sections("# Title\n## Part\nbody"), [("Part", "body")])


class ChunkTests(unittest.TestCase):
    def test_small_paragraphs_are_merged(self):
        self.assertEqual(chunk_document("aaa\n\nbbb", 20), ["aaa\n\nbbb"])

    def test_a_new_chunk_starts_when_the_limit_is_reached(self):
        self.assertEqual(chunk_document("aaaa\n\nbbbb\n\ncccc", 12), ["aaaa\n\nbbbb", "cccc"])

    def test_a_long_paragraph_is_split_by_words(self):
        self.assertEqual(chunk_document("one two three four five six", 12, 0), ["one two", "three four", "five six"])


class HelperTests(unittest.TestCase):
    def test_is_searchable(self):
        self.assertTrue(is_searchable("notes.md"))
        self.assertTrue(is_searchable("A.TXT"))
        self.assertFalse(is_searchable("image.png"))
        self.assertFalse(is_searchable(".hidden.md"))
        self.assertFalse(is_searchable("README"))

    def test_format_result(self):
        line = format_result(1, 0.87654, "docs/a.md", "", "line one\nline two")
        self.assertEqual(line, "1. 0.877 | docs/a.md | - | line one line two")


if __name__ == "__main__":
    unittest.main()
