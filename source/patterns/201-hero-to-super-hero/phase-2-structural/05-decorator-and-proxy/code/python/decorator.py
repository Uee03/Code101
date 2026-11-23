from abc import ABC, abstractmethod


class Sink(ABC):
    @abstractmethod
    def write(self, text: str) -> None:
        ...


class ConsoleSink(Sink):
    def write(self, text: str) -> None:
        print(text)


class SinkDecorator(Sink):
    def __init__(self, inner: Sink) -> None:
        self._inner = inner


class UpperSink(SinkDecorator):
    def write(self, text: str) -> None:
        self._inner.write(text.upper())


class PrefixSink(SinkDecorator):
    def __init__(self, inner: Sink, prefix: str) -> None:
        super().__init__(inner)
        self._prefix = prefix

    def write(self, text: str) -> None:
        self._inner.write(self._prefix + text)


class CountingSink(SinkDecorator):
    def __init__(self, inner: Sink) -> None:
        super().__init__(inner)
        self.count = 0

    def write(self, text: str) -> None:
        self.count += 1
        self._inner.write(text)


def demo() -> None:
    console = ConsoleSink()
    a = UpperSink(PrefixSink(console, "[app] "))
    b = PrefixSink(UpperSink(console), "[app] ")
    a.write("hello")
    b.write("hello")
    counted = CountingSink(console)
    counted.write("one")
    counted.write("two")
    print(f"writes counted: {counted.count}")
