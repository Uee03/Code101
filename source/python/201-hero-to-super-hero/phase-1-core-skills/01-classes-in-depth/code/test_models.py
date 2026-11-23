import unittest
from dataclasses import FrozenInstanceError

from models import Note, Notebook


class ModelTests(unittest.TestCase):
    def test_value_equality(self) -> None:
        self.assertEqual(Note("Read"), Note("Read"))

    def test_frozen_title(self) -> None:
        note = Note("Read")
        with self.assertRaises(FrozenInstanceError):
            setattr(note, "title", "Changed")

    def test_blank_title(self) -> None:
        with self.assertRaises(ValueError):
            Note("   ")

    def test_property_and_string(self) -> None:
        note = Note("Read the docs")
        self.assertEqual(note.word_count, 3)
        self.assertEqual(str(note), "Read the docs (3 words)")

    def test_composed_collections_are_independent(self) -> None:
        first, second = Notebook(), Notebook()
        first.add(Note("Read"))
        self.assertEqual(len(first), 1)
        self.assertEqual(len(second), 0)
