from abc import ABC, abstractmethod


class Node(ABC):
    def __init__(self, name: str) -> None:
        self.name = name

    @abstractmethod
    def size(self) -> int:
        ...

    @abstractmethod
    def lines(self, depth: int) -> list[str]:
        ...


class Document(Node):
    def __init__(self, name: str, size_kb: int) -> None:
        super().__init__(name)
        self._size_kb = size_kb

    def size(self) -> int:
        return self._size_kb

    def lines(self, depth: int) -> list[str]:
        return [f"{'  ' * depth}{self.name} ({self.size()})"]


class Folder(Node):
    def __init__(self, name: str) -> None:
        super().__init__(name)
        self._children: list[Node] = []

    def add(self, child: Node) -> "Folder":
        self._children.append(child)
        return self

    def size(self) -> int:
        return sum(child.size() for child in self._children)

    def lines(self, depth: int) -> list[str]:
        result = [f"{'  ' * depth}{self.name} ({self.size()})"]
        for child in self._children:
            result.extend(child.lines(depth + 1))
        return result


def demo() -> None:
    docs = Folder("docs").add(Document("b.txt", 20)).add(Document("c.txt", 30))
    root = Folder("root").add(Document("a.txt", 10)).add(docs)
    for line in root.lines(0):
        print(line)
    print(f"docs only: {docs.size()}")
