from abc import ABC, abstractmethod


class Catalog(ABC):
    @abstractmethod
    def get_price(self, product):
        ...

    @abstractmethod
    def set_price(self, product, cents):
        ...


class ShopCatalog(Catalog):
    def __init__(self, prices):
        self.prices = prices

    def get_price(self, product):
        return self.prices[product]

    def set_price(self, product, cents):
        self.prices[product] = cents


class PartnerCatalog(Catalog):
    def __init__(self, prices):
        self.prices = prices

    def get_price(self, product):
        return self.prices[product]

    def set_price(self, product, cents):
        pass


def show_price(catalog, product):
    print(f"{product}: {catalog.get_price(product)}")


# TODO 1: split Catalog into two small interfaces: PriceReader (get_price) and PriceWriter (set_price).
# TODO 2: ShopCatalog implements both. PartnerCatalog implements only PriceReader and loses its empty set_price.
# TODO 3: show_price asks for a PriceReader (use a type hint).
# TODO 4: delete the last two lines of the program (the partner.set_price call and the show_price after it).
#         The compiler or type checker would refuse them now, which is the point.

shop = ShopCatalog({"mug": 800})
partner = PartnerCatalog({"mug": 750})
show_price(shop, "mug")
show_price(partner, "mug")
shop.set_price("mug", 900)
show_price(shop, "mug")
partner.set_price("mug", 1)
show_price(partner, "mug")
