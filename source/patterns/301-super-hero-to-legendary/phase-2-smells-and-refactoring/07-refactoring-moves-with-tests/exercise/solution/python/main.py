from dataclasses import dataclass


def label(first, last, street, city, zip_code, express):
    text = f"{first} {last}\n{street}\n{zip_code} {city}"
    if express:
        text += "\nEXPRESS"
    return text


@dataclass(frozen=True)
class Address:
    street: str
    city: str
    zip_code: str


def label_v2(first, last, address, express):
    text = f"{first} {last}\n{address.street}\n{address.zip_code} {address.city}"
    if express:
        text += "\nEXPRESS"
    return text


CASES = [
    ("Ana", "Ruiz", "1 Main St", "Oslo", "0150", False),
    ("Bo", "Li", "9 Park Rd", "Bergen", "5003", True),
    ("Cy", "Ott", "3 Hill Way", "Tromso", "9008", True),
]

differences = 0
for first, last, street, city, zip_code, express in CASES:
    old = label(first, last, street, city, zip_code, express)
    new = label_v2(first, last, Address(street, city, zip_code), express)
    if old != new:
        differences += 1
print(f"{len(CASES)} cases, {differences} differences")
