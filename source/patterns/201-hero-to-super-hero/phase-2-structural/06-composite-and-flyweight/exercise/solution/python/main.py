from abc import ABC, abstractmethod


class Priced(ABC):
    @abstractmethod
    def cents(self) -> int:
        ...


class Product(Priced):
    def __init__(self, name: str, amount: int) -> None:
        self.name = name
        self._amount = amount

    def cents(self) -> int:
        return self._amount


class Bundle(Priced):
    def __init__(self, name: str) -> None:
        self.name = name
        self._children: list[Priced] = []

    def add(self, child: Priced) -> "Bundle":
        self._children.append(child)
        return self

    def cents(self) -> int:
        return sum(child.cents() for child in self._children)


laptop = Product("laptop", 90000)
mouse = Product("mouse", 2500)
cable = Product("cable", 2000)
print(f"laptop: {laptop.cents()}")
pack = Bundle("starter pack").add(laptop).add(mouse)
print(f"starter pack: {pack.cents()}")
combo = Bundle("combo").add(pack).add(cable)
print(f"combo: {combo.cents()}")
