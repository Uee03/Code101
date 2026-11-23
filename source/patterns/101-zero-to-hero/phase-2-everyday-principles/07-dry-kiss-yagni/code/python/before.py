from functools import reduce


def invoice_total(items, currency="EUR", rounding="HALF_UP"):
    total = reduce(lambda acc, item: acc + item[1] * item[2], items, 0)
    return total - total * 10 // 100 if total > 2500 else total


def receipt_total(items):
    total = 0
    for _, price, qty in items:
        total += price * qty
    if total > 2500:
        total = total - total * 10 // 100
    return total


def export_invoice_to_xml(items):
    return "<invoice/>"
