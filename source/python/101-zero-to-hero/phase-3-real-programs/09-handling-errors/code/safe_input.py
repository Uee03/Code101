from math import isfinite


def read_age():
    while True:
        try:
            age = int(input("Age: "))
        except ValueError:
            print("Use whole digits, for example 30.")
            continue
        if age < 0:
            print("Age cannot be negative.")
            continue
        return age


def read_bill():
    while True:
        try:
            bill = float(input("Bill amount: "))
        except ValueError:
            print("Use a number like 80.50, without a currency sign.")
            continue
        if not isfinite(bill) or bill < 0:
            print("Bill must be a finite number of zero or more.")
            continue
        return bill


age = read_age()
bill = read_bill()
print(f"Age accepted: {age}")
print(f"Bill accepted: {bill:.2f}")
