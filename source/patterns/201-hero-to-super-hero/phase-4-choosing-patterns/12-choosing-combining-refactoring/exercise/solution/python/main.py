from abc import ABC, abstractmethod


def old_ticket_price(kind: str, base: int) -> int:
    if kind == "child":
        return base // 2
    elif kind == "senior":
        return base * 70 // 100
    elif kind == "student":
        return base - 250
    return base


class Pricing(ABC):
    @abstractmethod
    def price(self, base: int) -> int:
        ...


class Regular(Pricing):
    def price(self, base: int) -> int:
        return base


class Child(Pricing):
    def price(self, base: int) -> int:
        return base // 2


class Senior(Pricing):
    def price(self, base: int) -> int:
        return base * 70 // 100


class Student(Pricing):
    def price(self, base: int) -> int:
        return base - 250


PRICING = {"regular": Regular(), "child": Child(), "senior": Senior(), "student": Student()}


def ticket_price(kind: str, base: int) -> int:
    return PRICING[kind].price(base)


KINDS = ["regular", "child", "senior", "student"]
for kind in KINDS:
    print(f"{kind}: {ticket_price(kind, 1000)}")
if all(ticket_price(kind, 1000) == old_ticket_price(kind, 1000) for kind in KINDS):
    print("Check passed: new pricing equals old pricing")
else:
    print("Check FAILED")
