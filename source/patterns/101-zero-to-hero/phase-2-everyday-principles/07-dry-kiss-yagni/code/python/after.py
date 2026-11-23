DISCOUNT_THRESHOLD_CENTS = 2500
DISCOUNT_PERCENT = 10


def total_cents(items):
    total = 0
    for _, price, qty in items:
        total += price * qty
    if total > DISCOUNT_THRESHOLD_CENTS:
        total -= total * DISCOUNT_PERCENT // 100
    return total
