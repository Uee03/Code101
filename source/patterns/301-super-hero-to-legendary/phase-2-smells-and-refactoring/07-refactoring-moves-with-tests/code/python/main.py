from shipping import Parcel, broken_cost, final_cost, legacy_cost, step1_cost


def grid():
    for weight in (1, 5, 20):
        for carrier in ("post", "fast", "freight"):
            for zone in ("domestic", "eu", "world"):
                for express in (False, True):
                    for insured in (False, True):
                        for fragile in (False, True):
                            yield weight, carrier, zone, express, insured, fragile


def compare(name, candidate, show_first=False):
    cases = list(grid())
    differences = []
    for weight, carrier, zone, express, insured, fragile in cases:
        expected = legacy_cost(weight, carrier, express, zone, insured, 10000, fragile)
        actual = candidate(carrier, Parcel(weight, zone, express, insured, 10000, fragile))
        if expected != actual:
            differences.append(((weight, carrier, zone, express, insured, fragile), expected, actual))
    print(f"{name}: {len(cases)} cases, {len(differences)} differences")
    if show_first and differences:
        (weight, carrier, zone, express, insured, fragile), expected, actual = differences[0]
        print(f"first difference: {weight} kg {carrier} {zone} express={express} insured={insured} fragile={fragile}: legacy {expected}, candidate {actual}")


def error_text(call):
    try:
        call()
    except ValueError as error:
        return str(error)
    return ""


def main():
    print(f"sample quote: {final_cost('fast', Parcel(5, 'eu', True, True, 10000, False))}")
    compare("step 1 (extract functions, parameter object)", step1_cost)
    compare("step 2 (polymorphic carriers, move method)", final_cost)
    compare("broken step (express applied last)", broken_cost, show_first=True)

    old = error_text(lambda: legacy_cost(1, "teleport", False, "eu", False, 0, False))
    new = error_text(lambda: final_cost("teleport", Parcel(1, "eu", False, False, 0, False)))
    print(f"error message preserved: {old == new and old != ''}")


main()
