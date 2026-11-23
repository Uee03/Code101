from dataclasses import dataclass


@dataclass(frozen=True)
class TreeType:
    name: str
    color: str


class TreeTypeFactory:
    def __init__(self) -> None:
        self._cache: dict[tuple[str, str], TreeType] = {}

    @property
    def count(self) -> int:
        return len(self._cache)

    def get(self, name: str, color: str) -> TreeType:
        key = (name, color)
        if key not in self._cache:
            self._cache[key] = TreeType(name, color)
        return self._cache[key]


class Tree:
    def __init__(self, x: int, y: int, kind: TreeType) -> None:
        self.x = x
        self.y = y
        self.kind = kind

    def draw(self) -> str:
        return f"{self.kind.name} ({self.kind.color}) at {self.x},{self.y}"


def demo() -> None:
    factory = TreeTypeFactory()
    forest = [
        Tree(1, 2, factory.get("oak", "green")),
        Tree(3, 4, factory.get("oak", "green")),
        Tree(5, 6, factory.get("pine", "dark green")),
        Tree(7, 8, factory.get("oak", "green")),
        Tree(9, 10, factory.get("pine", "dark green")),
    ]
    for tree in forest:
        print(tree.draw())
    print(f"trees: {len(forest)}, shared types: {factory.count}")
    print(f"same object: {forest[0].kind is forest[1].kind}")
