from pathlib import Path


path = Path(__file__).resolve().parent / "journal.txt"
entry = input("Journal entry: ")

with path.open("a", encoding="utf-8") as file:
    file.write(entry + "\n")

with path.open("r", encoding="utf-8") as file:
    print(file.read(), end="")
