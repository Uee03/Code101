from abc import ABC, abstractmethod


class Observer(ABC):
    @abstractmethod
    def update(self, price: int) -> None:
        ...


class PriceFeed:
    def __init__(self) -> None:
        self._observers: list[Observer] = []

    def subscribe(self, observer: Observer) -> None:
        self._observers.append(observer)

    def unsubscribe(self, observer: Observer) -> None:
        self._observers.remove(observer)

    def set_price(self, price: int) -> None:
        for observer in list(self._observers):
            observer.update(price)


class PriceLogger(Observer):
    def update(self, price: int) -> None:
        print(f"log: price is {price}")


class PriceAlert(Observer):
    def __init__(self, limit: int) -> None:
        self._limit = limit

    def update(self, price: int) -> None:
        if price > self._limit:
            print(f"ALERT: price {price} is above {self._limit}")


def demo() -> None:
    feed = PriceFeed()
    logger = PriceLogger()
    alert = PriceAlert(110)
    feed.subscribe(logger)
    feed.subscribe(alert)
    feed.set_price(100)
    feed.set_price(120)
    feed.unsubscribe(logger)
    feed.set_price(130)
