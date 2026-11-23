def make_rows(count: int) -> list[dict[str, object]]:
    return [{"id": n, "customer": f"c{n % 2000}", "amount": n % 97} for n in range(count)]


def customers_slow(rows: list[dict[str, object]]) -> list[str]:
    seen: list[str] = []
    for row in rows:
        customer = str(row["customer"])
        if customer not in seen:
            seen.append(customer)
    return seen


def customers_fast(rows: list[dict[str, object]]) -> list[str]:
    seen: dict[str, None] = {}
    for row in rows:
        seen.setdefault(str(row["customer"]), None)
    return list(seen)
