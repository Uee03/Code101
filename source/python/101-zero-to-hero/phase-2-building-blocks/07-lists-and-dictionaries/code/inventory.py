shopping = ["bread", "apples"]
shopping.append("milk")
print(f"First item: {shopping[0]}")
print(f"Items to buy: {len(shopping)}")

stock = {"bread": 4, "apples": 6, "milk": 2}
stock["bread"] = stock["bread"] - 1

for name in shopping:
    print(f"Buy: {name}")

for name, quantity in stock.items():
    print(f"{name}: {quantity} left")

if "rice" not in stock:
    print("Rice is not stocked.")
print(f"Rice count: {stock.get('rice', 0)}")
