def shipping_cents(method):
    if method == "standard":
        return 400
    if method == "express":
        return 1200
    return 0


# TODO 1: make a base class ShippingRule (use ABC and @abstractmethod) with a method cost_cents().
# TODO 2: make StandardShipping (400 cents) and ExpressShipping (1200 cents) that inherit from it.
# TODO 3: put one object of each in a dictionary named RULES, keyed "standard" and "express".
#         Then print the costs with RULES[method].cost_cents() and delete shipping_cents.

for method in ["standard", "express"]:
    print(f"{method}: {shipping_cents(method)}")
