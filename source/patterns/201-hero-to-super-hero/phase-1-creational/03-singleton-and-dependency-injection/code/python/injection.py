class Checkout:
    def __init__(self, tax_percent: int) -> None:
        self._tax_percent = tax_percent

    def total(self, net_cents: int) -> int:
        return net_cents + net_cents * self._tax_percent // 100


def demo() -> None:
    shop = Checkout(20)
    check = Checkout(0)
    print(f"shop total: {shop.total(1000)}")
    print(f"check total: {check.total(1000)}")
    print(f"shop total again: {shop.total(1000)}")
