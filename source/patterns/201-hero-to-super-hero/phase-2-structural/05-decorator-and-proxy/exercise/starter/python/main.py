from abc import ABC, abstractmethod


class Price(ABC):
    @abstractmethod
    def cents(self) -> int:
        ...


class BasePrice(Price):
    def __init__(self, amount: int) -> None:
        self._amount = amount

    def cents(self) -> int:
        return self._amount


class Tax(Price):
    def __init__(self, inner: Price, percent: int) -> None:
        self._inner = inner
        self._percent = percent

    def cents(self) -> int:
        net = self._inner.cents()
        return net + net * self._percent // 100


# TODO 1: write Discount(Price): __init__(inner, percent); cents() returns the inner price minus percent of it (use // 100).
# TODO 2: write Fee(Price): __init__(inner, extra_cents); cents() returns the inner price plus extra_cents.

base = BasePrice(1000)
print(f"base: {base.cents()}")
print(f"taxed: {Tax(base, 20).cents()}")
# TODO 3: build fee_last = Fee(Tax(Discount(base, 10), 20), 500) and fee_first = Tax(Fee(Discount(base, 10), 500), 20)
#         and print them as "fee last: ..." and "fee first: ..."
