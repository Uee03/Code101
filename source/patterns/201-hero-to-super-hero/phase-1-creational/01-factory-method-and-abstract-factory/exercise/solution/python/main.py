from abc import ABC, abstractmethod


class Formatter(ABC):
    @abstractmethod
    def format(self, text: str) -> str:
        ...


class PlainFormatter(Formatter):
    def format(self, text: str) -> str:
        return text


class ShoutFormatter(Formatter):
    def format(self, text: str) -> str:
        return text.upper() + "!"


class Printer(ABC):
    def print_line(self, text: str) -> None:
        print(self.create_formatter().format(text))

    @abstractmethod
    def create_formatter(self) -> Formatter:
        ...


class PlainPrinter(Printer):
    def create_formatter(self) -> Formatter:
        return PlainFormatter()


class ShoutPrinter(Printer):
    def create_formatter(self) -> Formatter:
        return ShoutFormatter()


printers = {"plain": PlainPrinter(), "shout": ShoutPrinter()}
for name in ("plain", "shout"):
    printers[name].print_line("hello")
