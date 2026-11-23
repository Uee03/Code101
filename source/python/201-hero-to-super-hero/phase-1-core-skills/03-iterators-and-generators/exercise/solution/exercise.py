from collections.abc import Iterable, Iterator


def long_titles(lines: Iterable[str], minimum: int) -> Iterator[str]:
    for line in lines:
        title = line.strip()
        if len(title) >= minimum:
            yield title


stream = long_titles([" A ", " Read ", "Docs"], 4)
assert list(stream) == ["Read", "Docs"]
assert list(stream) == []
print("Read, Docs; exhausted")
