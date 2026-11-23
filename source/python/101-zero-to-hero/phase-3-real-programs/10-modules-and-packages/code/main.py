from datetime import date
from math import ceil

from helpers.formatting import format_money
from totals import line_total


def main():
    delivery = date(2026, 12, 1)
    total_cents = line_total(125, 3)
    boxes = ceil(7 / 3)
    print(f"Delivery: {delivery.isoformat()}")
    print(f"Total: {format_money(total_cents)}")
    print(f"Boxes for 7 jars, 3 per box: {boxes}")


if __name__ == "__main__":
    main()
