import after
import before

CASES = [
    ("welcome coupon", [("pen", 150, 4), ("book", 1200, 1)], "standard", "WELCOME10", "ana@example.com"),
    ("capped coupon", [("cable", 400, 1)], "pickup", "FIVEOFF", "bo@example.com"),
    ("no coupon", [("lamp", 2500, 2)], "express", None, "cy@example.com"),
    ("empty cart", [], "standard", None, "di@example.com"),
    ("unknown shipping", [("pen", 150, 1)], "drone", None, "ed@example.com"),
]

for label, items, shipping, coupon, email in CASES:
    old = before.checkout(items, shipping, coupon, email)
    new = after.place_order(items, shipping, coupon, email)
    print(f"--- {label} ---")
    for line in new:
        print(line)
    print(f"same as before: {old == new}")
