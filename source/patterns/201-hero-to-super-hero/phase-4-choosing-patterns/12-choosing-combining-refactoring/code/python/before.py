def checkout(items, shipping, coupon, email):
    lines = []
    if len(items) == 0:
        return ["error: cart is empty"]
    for name, price, quantity in items:
        if quantity <= 0:
            return [f"error: bad quantity for {name}"]
    subtotal = 0
    for name, price, quantity in items:
        subtotal += price * quantity
    lines.append(f"subtotal: {subtotal}")
    discount = 0
    if coupon == "WELCOME10":
        discount = subtotal * 10 // 100
    elif coupon == "FIVEOFF":
        discount = min(500, subtotal)
    lines.append(f"discount: {discount}")
    if shipping == "pickup":
        ship = 0
    elif shipping == "standard":
        ship = 500
    elif shipping == "express":
        ship = 1500
    else:
        return [f"error: unknown shipping {shipping}"]
    lines.append(f"shipping: {ship}")
    taxable = subtotal - discount
    tax = taxable * 20 // 100
    lines.append(f"tax: {tax}")
    total = taxable + tax + ship
    lines.append(f"total: {total}")
    lines.append(f"email to {email}: order total {total}")
    lines.append("log: order placed")
    return lines
