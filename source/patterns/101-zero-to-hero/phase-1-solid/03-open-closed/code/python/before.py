def discounted_total(customer_type, total_cents):
    if customer_type == "regular":
        return total_cents
    elif customer_type == "vip":
        return total_cents - total_cents * 20 // 100
    elif customer_type == "student":
        return total_cents - total_cents * 10 // 100
    return total_cents
