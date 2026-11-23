ITEMS = [("Mug", 800, 3), ("Plate", 1250, 2)]

NEARBY_SHIPPING_CENTS = 500
FAR_SHIPPING_CENTS = 1500
NEARBY_COUNTRIES = ("DE", "FR")


def subtotal(items):
    total = 0
    for _, price, qty in items:
        total += price * qty
    return total


def shipping_cents(country):
    if country in NEARBY_COUNTRIES:
        return NEARBY_SHIPPING_CENTS
    return FAR_SHIPPING_CENTS


def order_summary(items, country):
    total = subtotal(items) + shipping_cents(country)
    print("Order total: " + str(total // 100) + "." + str(total % 100).zfill(2))


order_summary(ITEMS, "FR")
order_summary(ITEMS, "US")
