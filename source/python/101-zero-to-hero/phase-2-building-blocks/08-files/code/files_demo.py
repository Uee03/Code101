import csv
from pathlib import Path


folder = Path(__file__).resolve().parent
note_path = folder / "note.txt"

with note_path.open("w", encoding="utf-8") as file:
    file.write("Remember the milk.\n")

with note_path.open("r", encoding="utf-8") as file:
    note = file.read()
print(note, end="")

rows = [
    {"item": "bread", "quantity": 2},
    {"item": "apples", "quantity": 3},
]
csv_path = folder / "shopping.csv"

with csv_path.open("w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(file, fieldnames=["item", "quantity"])
    writer.writeheader()
    writer.writerows(rows)

with csv_path.open("r", newline="", encoding="utf-8") as file:
    reader = csv.DictReader(file)
    for row in reader:
        quantity = int(row["quantity"])
        print(f"{row['item']}: {quantity}")
