from abc import ABC, abstractmethod


class PriceReader(ABC):
    @abstractmethod
    def get_price(self, product):
        ...


class PriceWriter(ABC):
    @abstractmethod
    def set_price(self, product, cents):
        ...


class ShopCatalog(PriceReader, PriceWriter):
    def __init__(self, prices):
        self.prices = prices

    def get_price(self, product):
        return self.prices[product]

    def set_price(self, product, cents):
        self.prices[product] = cents


class PartnerCatalog(PriceReader):
    def __init__(self, prices):
        self.prices = prices

    def get_price(self, product):
        return self.prices[product]


def show_price(catalog: PriceReader, product):
    print(f"{product}: {catalog.get_price(product)}")


shop = ShopCatalog({"mug": 800})
partner = PartnerCatalog({"mug": 750})
show_price(shop, "mug")
show_price(partner, "mug")
shop.set_price("mug", 900)
show_price(shop, "mug")
