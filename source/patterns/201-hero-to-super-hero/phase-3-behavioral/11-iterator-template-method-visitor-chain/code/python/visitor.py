from abc import ABC, abstractmethod
from typing import Any


class Shape(ABC):
    @abstractmethod
    def accept(self, visitor: "Visitor") -> Any:
        ...


class Square(Shape):
    def __init__(self, side: int) -> None:
        self.side = side

    def accept(self, visitor: "Visitor") -> Any:
        return visitor.visit_square(self)


class Rect(Shape):
    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height

    def accept(self, visitor: "Visitor") -> Any:
        return visitor.visit_rect(self)


class Visitor(ABC):
    @abstractmethod
    def visit_square(self, square: Square) -> Any:
        ...

    @abstractmethod
    def visit_rect(self, rect: Rect) -> Any:
        ...


class AreaVisitor(Visitor):
    def visit_square(self, square: Square) -> int:
        return square.side * square.side

    def visit_rect(self, rect: Rect) -> int:
        return rect.width * rect.height


class DescribeVisitor(Visitor):
    def visit_square(self, square: Square) -> str:
        return f"square {square.side}"

    def visit_rect(self, rect: Rect) -> str:
        return f"rect {rect.width}x{rect.height}"


def demo() -> None:
    shapes: list[Shape] = [Square(3), Rect(2, 5)]
    area = AreaVisitor()
    describe = DescribeVisitor()
    total = 0
    for shape in shapes:
        value = shape.accept(area)
        total += value
        print(f"{shape.accept(describe)} -> area {value}")
    print(f"total area: {total}")
