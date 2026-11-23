import after
import before
import lookalikes

ITEMS = [("Notebook", 1200, 2), ("Pen", 150, 4)]


def describe(problem):
    if problem == "":
        return "ok"
    return problem


print("--- before ---")
print(f"Invoice: {before.invoice_total(ITEMS)}")
print(f"Receipt: {before.receipt_total(ITEMS)}")

print("--- after ---")
print(f"Invoice: {after.total_cents(ITEMS)}")
print(f"Receipt: {after.total_cents(ITEMS)}")

print("--- lookalikes ---")
print("Username 'al': " + describe(lookalikes.username_problem("al")))
print("Title with 30 letters: " + describe(lookalikes.product_title_problem("x" * 30)))
