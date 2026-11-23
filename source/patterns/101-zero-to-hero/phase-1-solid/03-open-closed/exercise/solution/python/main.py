from abc import ABC, abstractmethod


class ShippingRule(ABC):
    @abstractmethod
    def cost_cents(self):
        ...


class StandardShipping(ShippingRule):
    def cost_cents(self):
        return 400


class ExpressShipping(ShippingRule):
    def cost_cents(self):
        return 1200


RULES = {"standard": StandardShipping(), "express": ExpressShipping()}

for method in ["standard", "express"]:
    print(f"{method}: {RULES[method].cost_cents()}")
