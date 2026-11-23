from abc import ABC, abstractmethod


class Formatter(ABC):
    @abstractmethod
    def format(self, text: str) -> str:
        ...


class PlainFormatter(Formatter):
    def format(self, text: str) -> str:
        return text


class Printer(ABC):
    def print_line(self, text: str) -> None:
        print(self.create_formatter().format(text))

    @abstractmethod
    def create_formatter(self) -> Formatter:
        ...


class PlainPrinter(Printer):
    def create_formatter(self) -> Formatter:
        return PlainFormatter()


# TODO 1: write ShoutFormatter whose format returns the text in upper case followed by "!".
# TODO 2: write ShoutPrinter whose create_formatter returns a ShoutFormatter.
# TODO 3: add "shout": ShoutPrinter() to the dictionary below.

printers = {"plain": PlainPrinter()}
for name in ("plain", "shout"):
    printers[name].print_line("hello")
