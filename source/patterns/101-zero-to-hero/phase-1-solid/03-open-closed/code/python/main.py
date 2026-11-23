import after
import before
import new_rules

TOTAL = 5000
CUSTOMERS = ["regular", "vip", "student", "employee"]

print("--- before ---")
for customer in CUSTOMERS:
    print(f"{customer}: {before.discounted_total(customer, TOTAL)}")

print("--- after ---")
rules = {
    "regular": after.NoDiscount(),
    "vip": after.PercentDiscount(20),
    "student": after.PercentDiscount(10),
    "employee": new_rules.FlatDiscount(500),
}
for customer in CUSTOMERS:
    print(f"{customer}: {after.final_total(rules[customer], TOTAL)}")
