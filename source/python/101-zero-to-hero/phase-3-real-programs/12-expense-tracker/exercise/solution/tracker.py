import csv


FIELDS = ["description", "cents"]


def format_money(cents):
    return f"{cents // 100}.{cents % 100:02d}"


def total_expenses(expenses):
    total = 0
    for expense in expenses:
        total = total + expense["cents"]
    return total


def load_expenses(path):
    expenses = []
    try:
        with path.open("r", newline="", encoding="utf-8") as file:
            reader = csv.DictReader(file)
            if reader.fieldnames is None:
                return []
            if reader.fieldnames != FIELDS:
                raise ValueError("CSV header must be description,cents")
            for row in reader:
                if None in row or row["description"] is None or row["cents"] is None:
                    raise ValueError("CSV row needs exactly two fields")
                description = row["description"].strip()
                cents = int(row["cents"])
                if not description or cents <= 0:
                    raise ValueError("CSV rows need a description and positive cents")
                expenses.append({"description": description, "cents": cents})
    except FileNotFoundError:
        return []
    return expenses


def save_expenses(path, expenses):
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(expenses)
