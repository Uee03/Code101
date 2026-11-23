from dataclasses import dataclass, field


@dataclass
class ReadingList:
    titles: list[str] = field(default_factory=list)

    @property
    def total_words(self) -> int:
        # TODO: calculate a word count across this list's titles.
        return 0


first, second = ReadingList(), ReadingList()
first.titles.append("Read the docs")
assert first.total_words == 3
assert second.total_words == 0
print(first.total_words, second.total_words)
