import copy


class Unit:
    def __init__(self, name: str, hp: int, items: list[str]) -> None:
        self.name = name
        self.hp = hp
        self.items = items

    def clone(self) -> "Unit":
        return Unit(self.name, self.hp, list(self.items))

    def describe(self) -> str:
        return f"{self.name} hp={self.hp} items={', '.join(self.items)}"


def demo() -> None:
    archer = Unit("archer", 30, ["bow"])
    registry = {"archer": archer}

    scout = registry["archer"].clone()
    scout.name = "scout"
    scout.items.append("map")
    print(archer.describe())
    print(scout.describe())

    shallow = copy.copy(archer)
    shallow.items.append("torch")
    print(archer.describe())
