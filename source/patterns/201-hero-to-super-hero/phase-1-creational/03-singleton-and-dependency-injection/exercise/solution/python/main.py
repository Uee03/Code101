class Logger:
    def __init__(self) -> None:
        self.lines: list[str] = []

    def log(self, text: str) -> None:
        self.lines.append(text)


class Greeter:
    def __init__(self, logger: Logger) -> None:
        self._logger = logger

    def greet(self, name: str) -> str:
        self._logger.log(f"greeting {name}")
        return f"Hello, {name}"


shared = Logger()
Greeter(shared).greet("Ana")
Greeter(shared).greet("Bo")
print(", ".join(shared.lines))
other = Logger()
print(f"other has {len(other.lines)} lines")
