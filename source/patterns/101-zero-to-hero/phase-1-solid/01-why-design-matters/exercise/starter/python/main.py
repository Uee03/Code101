ITEMS = [("Mug", 800, 3), ("Plate", 1250, 2)]


def order_summary(items, country):
    total = 0
    for name, price, qty in items:
        total = total + price * qty
    if country == "DE":
        total = total + 500
    elif country == "FR":
        total = total + 500
    else:
        total = total + 1500
    print("Order total: " + str(total // 100) + "." + str(total % 100).zfill(2))


# TODO 1: write subtotal(items) that returns the sum of price * qty.
# TODO 2: write shipping_cents(country) that returns 500 for "DE" or "FR", otherwise 1500.
#         Give 500 and 1500 names (constants) so nobody has to guess what they mean.
# TODO 3: rewrite order_summary to use both helpers. The printed lines must not change.

order_summary(ITEMS, "FR")
order_summary(ITEMS, "US")
