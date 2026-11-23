events = [
    {"id": 1, "points": 5},
    {"id": 2, "points": 3},
    {"id": 1, "points": 5},
    {"id": 2, "points": 3},
    {"id": 3, "points": 1},
]


class Scoreboard:
    def __init__(self):
        self.total = 0
        # TODO 1: create a set that remembers the ids already applied.

    def apply(self, event):
        # TODO 2: if the id was applied before, return False without changing the total.
        #         Otherwise remember the id, add the points and return True.
        self.total += event["points"]
        return True


board = Scoreboard()
duplicates = 0
for event in events:
    if not board.apply(event):
        duplicates += 1
print(f"total points: {board.total}")
print(f"duplicates ignored: {duplicates}")
