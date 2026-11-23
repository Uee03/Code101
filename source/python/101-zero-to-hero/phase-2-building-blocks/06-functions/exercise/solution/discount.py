def discounted_price(price, percent):
    saving = price * percent / 100
    return price - saving


sale_price = discounted_price(80, 25)
print(f"Sale price: {sale_price:.2f}")
