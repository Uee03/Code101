DISCOUNT_THRESHOLD_CENTS = 2500
DISCOUNT_PERCENT = 10


def format_money(cents):
    return f"{cents // 100}.{cents % 100:02d}"


def subtotal(items):
    total = 0
    for _, price, qty in items:
        total += price * qty
    return total


def apply_discount(total):
    if total > DISCOUNT_THRESHOLD_CENTS:
        return total - total * DISCOUNT_PERCENT // 100
    return total


def invoice_lines(items, total):
    lines = ["INVOICE"]
    for name, price, qty in items:
        lines.append(f"{name} x{qty} = {format_money(price * qty)}")
    lines.append(f"Total: {format_money(total)}")
    return lines


def send_email(address):
    print(f"Email sent to {address}")


def checkout(items, email):
    total = apply_discount(subtotal(items))
    for line in invoice_lines(items, total):
        print(line)
    send_email(email)
