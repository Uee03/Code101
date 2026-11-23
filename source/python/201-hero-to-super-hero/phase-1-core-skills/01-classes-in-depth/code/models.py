from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Note:
    title: str

    def __post_init__(self) -> None:
        if not self.title.strip():
            raise ValueError("title must not be blank")

    @property
    def word_count(self) -> int:
        return len(self.title.split())

    def __str__(self) -> str:
        return f"{self.title} ({self.word_count} words)"


@dataclass
class Notebook:
    notes: list[Note] = field(default_factory=list)

    def add(self, note: Note) -> None:
        self.notes.append(note)

    def __len__(self) -> int:
        return len(self.notes)


if __name__ == "__main__":
    first = Notebook()
    second = Notebook()
    first.add(Note("Read the docs"))
    print(first.notes[0])
    print(f"notebooks: {len(first)}, {len(second)}")
    print(f"equal values: {Note('Read') == Note('Read')}")
