def old_ticket_price(kind: str, base: int) -> int:
    if kind == "child":
        return base // 2
    elif kind == "senior":
        return base * 70 // 100
    elif kind == "student":
        return base - 250
    return base


# TODO 1: write an abstract class Pricing (ABC) with an abstract method price(base).
#         Then write Regular, Child, Senior and Student, each returning the same value as its branch above.
# TODO 2: make a dictionary PRICING from the kind name ("regular", "child", "senior", "student") to a Pricing object.
# TODO 3: write ticket_price(kind, base) that looks the kind up in PRICING (no if chain).

KINDS = ["regular", "child", "senior", "student"]
# TODO 4: for each kind print "<kind>: <ticket_price(kind, 1000)>". Then print
#         "Check passed: new pricing equals old pricing" if every kind gives the same result as old_ticket_price,
#         otherwise print "Check FAILED".
