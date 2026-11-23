from dataclasses import dataclass


@dataclass(frozen=True)
class Snapshot:
    hp: int
    gold: int
    items: tuple[str, ...]


class Player:
    def __init__(self, hp: int, gold: int, items: list[str]) -> None:
        self.hp = hp
        self.gold = gold
        self.items = items

    def save(self) -> Snapshot:
        return Snapshot(self.hp, self.gold, tuple(self.items))

    def restore(self, snapshot: Snapshot) -> None:
        self.hp = snapshot.hp
        self.gold = snapshot.gold
        self.items = list(snapshot.items)

    def describe(self) -> str:
        return f"hp={self.hp} gold={self.gold} items={', '.join(self.items)}"


def demo() -> None:
    player = Player(100, 0, ["sword"])
    saved = [player.save()]
    player.hp = 70
    player.items.append("map")
    saved.append(player.save())
    player.hp = 10
    player.gold = 25
    print(player.describe())
    player.restore(saved.pop())
    print(player.describe())
    player.restore(saved.pop())
    print(player.describe())
