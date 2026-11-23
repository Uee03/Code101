class Logger:
    _instance = None

    def __init__(self) -> None:
        self.lines: list[str] = []

    @classmethod
    def instance(cls) -> "Logger":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def log(self, text: str) -> None:
        self.lines.append(text)


class Greeter:
    def greet(self, name: str) -> str:
        Logger.instance().log(f"greeting {name}")
        return f"Hello, {name}"


# TODO 1: give Greeter an __init__ that receives a logger and stores it in self._logger.
# TODO 2: make greet call self._logger.log(...) instead of Logger.instance().log(...).
# TODO 3: delete _instance and instance() from Logger: nobody needs them any more.

shared = Logger()
Greeter(shared).greet("Ana")
Greeter(shared).greet("Bo")
print(", ".join(shared.lines))
other = Logger()
print(f"other has {len(other.lines)} lines")
