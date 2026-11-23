from typing import Optional


class Handler:
    def __init__(self, name: str, limit: int) -> None:
        self._name = name
        self._limit = limit
        self._next: Optional["Handler"] = None

    def set_next(self, handler: "Handler") -> "Handler":
        self._next = handler
        return handler

    def handle(self, amount: int) -> str:
        if amount <= self._limit:
            return f"{amount}: approved by {self._name}"
        if self._next is not None:
            return self._next.handle(amount)
        return f"{amount}: nobody can approve"


def demo() -> None:
    manager = Handler("manager", 100)
    manager.set_next(Handler("director", 1000)).set_next(Handler("ceo", 10000))
    for amount in (50, 500, 5000, 50000):
        print(manager.handle(amount))
