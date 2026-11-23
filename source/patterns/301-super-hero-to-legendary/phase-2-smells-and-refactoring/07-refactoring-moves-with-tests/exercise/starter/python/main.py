from dataclasses import dataclass


def label(first, last, street, city, zip_code, express):
    text = f"{first} {last}\n{street}\n{zip_code} {city}"
    if express:
        text += "\nEXPRESS"
    return text


# TODO 1: write a frozen dataclass Address with the fields street, city and zip_code.

# TODO 2: write label_v2(first, last, address, express) that returns exactly what label returns,
#         reading address.street, address.city and address.zip_code.

CASES = [
    ("Ana", "Ruiz", "1 Main St", "Oslo", "0150", False),
    ("Bo", "Li", "9 Park Rd", "Bergen", "5003", True),
    ("Cy", "Ott", "3 Hill Way", "Tromso", "9008", True),
]

differences = 0
for first, last, street, city, zip_code, express in CASES:
    old = label(first, last, street, city, zip_code, express)
    new = None  # TODO 3: call label_v2 with an Address built from street, city and zip_code
    if old != new:
        differences += 1
print(f"{len(CASES)} cases, {differences} differences")
