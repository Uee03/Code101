cart = ["bread", "milk", "bread"]
prices = {"bread": 2, "milk": 3}
total = 0

for name in cart:
    total = total + prices[name]

print(f"Cart total: {total}")
