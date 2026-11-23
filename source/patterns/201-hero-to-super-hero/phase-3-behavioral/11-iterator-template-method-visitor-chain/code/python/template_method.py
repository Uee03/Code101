from abc import ABC, abstractmethod


class Report(ABC):
    def render(self, rows: list[tuple[str, int]]) -> list[str]:
        lines = [self.header()]
        for name, quantity in rows:
            lines.append(self.format_row(name, quantity))
        lines.extend(self.footer())
        return lines

    @abstractmethod
    def header(self) -> str:
        ...

    @abstractmethod
    def format_row(self, name: str, quantity: int) -> str:
        ...

    def footer(self) -> list[str]:
        return []


class CsvReport(Report):
    def header(self) -> str:
        return "name,qty"

    def format_row(self, name: str, quantity: int) -> str:
        return f"{name},{quantity}"


class TextReport(Report):
    def header(self) -> str:
        return "== Report =="

    def format_row(self, name: str, quantity: int) -> str:
        return f"{name} x{quantity}"

    def footer(self) -> list[str]:
        return ["== end =="]


def demo() -> None:
    rows = [("apple", 3), ("pear", 5)]
    print("[csv]")
    for line in CsvReport().render(rows):
        print(line)
    print("[text]")
    for line in TextReport().render(rows):
        print(line)
