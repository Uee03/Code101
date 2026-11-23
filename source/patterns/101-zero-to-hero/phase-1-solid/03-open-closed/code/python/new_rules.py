from after import DiscountRule


class FlatDiscount(DiscountRule):
    def __init__(self, cents):
        self.cents = cents

    def apply(self, total_cents):
        return max(total_cents - self.cents, 0)
