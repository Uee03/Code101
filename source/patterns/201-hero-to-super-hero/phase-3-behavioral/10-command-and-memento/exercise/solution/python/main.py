from abc import ABC, abstractmethod


class Counter:
    def __init__(self) -> None:
        self.value = 0


class Command(ABC):
    @abstractmethod
    def execute(self) -> None:
        ...

    @abstractmethod
    def undo(self) -> None:
        ...


class Add(Command):
    def __init__(self, counter: Counter, amount: int) -> None:
        self._counter = counter
        self._amount = amount

    def execute(self) -> None:
        self._counter.value += self._amount

    def undo(self) -> None:
        self._counter.value -= self._amount


class Multiply(Command):
    def __init__(self, counter: Counter, factor: int) -> None:
        self._counter = counter
        self._factor = factor
        self._before = 0

    def execute(self) -> None:
        self._before = self._counter.value
        self._counter.value *= self._factor

    def undo(self) -> None:
        self._counter.value = self._before


class History:
    def __init__(self) -> None:
        self._done: list[Command] = []

    def run(self, command: Command) -> None:
        command.execute()
        self._done.append(command)

    def undo(self) -> None:
        self._done.pop().undo()


counter = Counter()
history = History()
history.run(Add(counter, 5))
print(f"value: {counter.value}")
history.run(Multiply(counter, 3))
print(f"value: {counter.value}")
history.undo()
print(f"value: {counter.value}")
history.undo()
print(f"value: {counter.value}")
