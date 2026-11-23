from collections.abc import Iterable, Iterator
from typing import Self


class Countdown:
    def __init__(self, start: int) -> None:
        self.remaining = start

    def __iter__(self) -> Self:
        return self

    def __next__(self) -> int:
        if self.remaining <= 0:
            raise StopIteration
        value = self.remaining
        self.remaining -= 1
        return value


def clean_titles(lines: Iterable[str]) -> Iterator[str]:
    for line in lines:
        title = line.strip()
        if title:
            yield title


if __name__ == "__main__":
    counter = Countdown(3)
    print(next(counter))
    print(list(counter))
    print(list(counter))
    print(list(clean_titles([" One ", " ", "Two"])))
