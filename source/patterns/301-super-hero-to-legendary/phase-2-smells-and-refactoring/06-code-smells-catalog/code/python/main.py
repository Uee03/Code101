from pathlib import Path

import smelly
from scanner import MAX_METHODS, flags, scan


def main():
    items = [("pen", 150, 2), ("book", 1200, 1)]
    print(smelly.make_invoice("Ana", "ana@example.com", "1 Main St", "Oslo", "0150", items, "SAVE10", "DE", True))

    manager = smelly.OrderManager()
    manager.add({"id": 1, "amount": 100})
    manager.add({"id": 2, "amount": 250})
    print(manager.print_report())

    functions, classes = scan(Path(__file__).with_name("smelly.py"))
    print(f"scanned {len(functions)} functions or methods")
    for item in functions:
        problems = flags(item)
        if problems:
            print(f"{item['name']}: lines={item['lines']} params={item['params']} nesting={item['nesting']} -> {', '.join(problems)}")
    for name, count in classes:
        if count > MAX_METHODS:
            print(f"class {name}: methods={count} -> large class")


main()
