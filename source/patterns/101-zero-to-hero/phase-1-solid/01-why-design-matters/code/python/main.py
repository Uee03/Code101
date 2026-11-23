import after
import before

ITEMS = [("Notebook", 1200, 2), ("Pen", 150, 4)]
EMAIL = "ana@example.com"

print("--- before ---")
before.checkout(ITEMS, EMAIL)
print("--- after ---")
after.checkout(ITEMS, EMAIL)
