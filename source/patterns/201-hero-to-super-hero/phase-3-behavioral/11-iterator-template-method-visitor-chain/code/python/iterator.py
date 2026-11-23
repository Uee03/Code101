from typing import Iterator


class Playlist:
    def __init__(self, songs: list[str]) -> None:
        self._songs = songs

    def __iter__(self) -> Iterator[str]:
        return iter(self._songs)

    def backwards(self) -> Iterator[str]:
        index = len(self._songs) - 1
        while index >= 0:
            yield self._songs[index]
            index -= 1


def demo() -> None:
    playlist = Playlist(["Intro", "Verse", "Chorus"])
    print(f"forward: {', '.join(playlist)}")
    print(f"backwards: {', '.join(playlist.backwards())}")
    first = iter(playlist)
    second = iter(playlist)
    print(f"first: {next(first)}, {next(first)}")
    print(f"second: {next(second)}")
