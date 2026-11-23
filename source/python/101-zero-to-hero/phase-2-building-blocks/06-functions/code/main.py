def line_total(price, quantity):
    subtotal = price * quantity
    return subtotal


bread_total = line_total(2.5, 2)
fruit_total = line_total(1.2, 3)
order_total = bread_total + fruit_total

print(f"Bread: {bread_total:.2f}")
print(f"Fruit: {fruit_total:.2f}")
print(f"Order: {order_total:.2f}")
