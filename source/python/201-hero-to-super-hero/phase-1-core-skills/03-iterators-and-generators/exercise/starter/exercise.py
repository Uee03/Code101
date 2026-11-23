from collections.abc import Iterable, Iterator


def long_titles(lines: Iterable[str], minimum: int) -> Iterator[str]:
    for line in lines:
        # TODO: strip the line and yield it only when its length is >= minimum.
        if False:
            yield line


stream = long_titles([" A ", " Read ", "Docs"], 4)
assert list(stream) == ["Read", "Docs"]
assert list(stream) == []
print("Read, Docs; exhausted")
