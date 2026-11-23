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


# TODO 1: write Multiply(Command). __init__ receives the counter and a factor.
#         execute() remembers the old value in self._before and multiplies; undo() puts self._before back.


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
# TODO 2: run Multiply(counter, 3) and print the value, then call history.undo() twice, printing the value after each undo
