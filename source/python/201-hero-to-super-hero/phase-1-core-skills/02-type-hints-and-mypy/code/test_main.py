import unittest
from dataclasses import dataclass

from main import Note, describe, find_note, titles


@dataclass
class Article:
    title: str


class TypeTests(unittest.TestCase):
    def test_structural_protocol(self) -> None:
        self.assertEqual(titles([Article("Article")]), ["ARTICLE"])

    def test_found(self) -> None:
        self.assertEqual(describe(find_note([Note(1, "Read")], 1)), "Read")

    def test_missing_is_explicit(self) -> None:
        self.assertEqual(describe(find_note([], 1)), "missing")
