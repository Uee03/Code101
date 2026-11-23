import csv
import sys


def spread(values):
    # TODO 1: return a tuple (smallest value, largest value)
    return None


def slowest_prompt(rows):
    # TODO 2: return the prompt_id of the row with the largest total_s (the values are text in the CSV)
    return None


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "results.csv"
    with open(path, newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    for model in sorted({row["model"] for row in rows}):
        mine = [row for row in rows if row["model"] == model]
        low, high = spread([float(row["total_s"]) for row in mine])
        print(f"{model}: total_s min {low:.2f} max {high:.2f}, slowest prompt {slowest_prompt(mine)}")


if __name__ == "__main__":
    main()
