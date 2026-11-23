from pathlib import Path
from tempfile import TemporaryDirectory

from tracker import format_money, load_expenses, save_expenses, total_expenses


with TemporaryDirectory() as folder:
    path = Path(folder) / "expenses.csv"
    assert load_expenses(path) == []
    expenses = [{"description": "Tea, large", "cents": 250}]
    save_expenses(path, expenses)
    assert load_expenses(path) == expenses
    assert total_expenses(expenses) == 250
    assert format_money(205) == "2.05"

print("Self-check passed.")
