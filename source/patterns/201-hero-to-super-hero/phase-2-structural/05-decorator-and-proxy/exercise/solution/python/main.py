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


class Discount(Price):
    def __init__(self, inner: Price, percent: int) -> None:
        self._inner = inner
        self._percent = percent

    def cents(self) -> int:
        gross = self._inner.cents()
        return gross - gross * self._percent // 100


class Fee(Price):
    def __init__(self, inner: Price, extra_cents: int) -> None:
        self._inner = inner
        self._extra_cents = extra_cents

    def cents(self) -> int:
        return self._inner.cents() + self._extra_cents


base = BasePrice(1000)
print(f"base: {base.cents()}")
print(f"taxed: {Tax(base, 20).cents()}")
fee_last = Fee(Tax(Discount(base, 10), 20), 500)
fee_first = Tax(Fee(Discount(base, 10), 500), 20)
print(f"fee last: {fee_last.cents()}")
print(f"fee first: {fee_first.cents()}")
