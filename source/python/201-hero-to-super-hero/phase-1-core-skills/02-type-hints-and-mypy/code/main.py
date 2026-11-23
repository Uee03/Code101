from collections.abc import Iterable
from dataclasses import dataclass
from typing import Protocol


class HasTitle(Protocol):
    @property
    def title(self) -> str: ...


@dataclass
class Note:
    id: int
    title: str


def titles(items: Iterable[HasTitle]) -> list[str]:
    return [item.title.upper() for item in items]


def find_note(notes: Iterable[Note], note_id: int) -> Note | None:
    for note in notes:
        if note.id == note_id:
            return note
    return None


def describe(note: Note | None) -> str:
    if note is None:
        return "missing"
    return note.title


if __name__ == "__main__":
    notes = [Note(1, "Read docs")]
    print(titles(notes))
    print(describe(find_note(notes, 2)))
