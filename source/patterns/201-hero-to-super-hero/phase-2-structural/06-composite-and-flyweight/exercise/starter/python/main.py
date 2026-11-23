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


# TODO 1: write Bundle(Priced). __init__(name) creates an empty list of children.
#         add(child) appends a Priced child and returns self. cents() returns the sum of the children's cents().

laptop = Product("laptop", 90000)
mouse = Product("mouse", 2500)
cable = Product("cable", 2000)
print(f"laptop: {laptop.cents()}")
# TODO 2: make pack = Bundle("starter pack") holding laptop and mouse, and print "starter pack: ..."
# TODO 3: make combo = Bundle("combo") holding pack and cable, and print "combo: ..."
