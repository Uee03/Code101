import csv
from pathlib import Path

from tracker import format_money, load_expenses, save_expenses, total_expenses


def read_cents():
    while True:
        try:
            cents = int(input("Amount in cents (250 = 2.50): "))
        except ValueError:
            print("Use whole cents, for example 250.")
            continue
        if cents <= 0:
            print("Amount must be positive.")
            continue
        return cents


def main():
    path = Path(__file__).resolve().parent / "expenses.csv"
    try:
        expenses = load_expenses(path)
    except (OSError, ValueError, csv.Error) as error:
        print(f"Cannot load expenses: {error}")
        return

    while True:
        print("1 Add | 2 List | 3 Total | 4 Quit | 5 Count")
        choice = input("Choice: ")
        if choice == "1":
            description = input("Description: ").strip()
            if not description:
                print("Description cannot be empty.")
                continue
            cents = read_cents()
            updated = expenses + [{"description": description, "cents": cents}]
            try:
                save_expenses(path, updated)
            except OSError as error:
                print(f"Cannot save expenses: {error}")
                continue
            expenses = updated
            print("Saved.")
        elif choice == "2":
            if not expenses:
                print("No expenses yet.")
            for expense in expenses:
                amount = format_money(expense["cents"])
                print(f"{expense['description']}: {amount}")
        elif choice == "3":
            total = total_expenses(expenses)
            print(f"Total: {format_money(total)}")
        elif choice == "4":
            print("Goodbye!")
            break
        elif choice == "5":
            # TODO: print the number of saved expenses using len(expenses).
            print("TODO")
        else:
            print("Choose 1, 2, 3, 4 or 5.")


if __name__ == "__main__":
    main()
