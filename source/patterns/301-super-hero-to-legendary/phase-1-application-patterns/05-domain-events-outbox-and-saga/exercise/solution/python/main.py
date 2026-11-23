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
        self.applied = set()

    def apply(self, event):
        if event["id"] in self.applied:
            return False
        self.applied.add(event["id"])
        self.total += event["points"]
        return True


board = Scoreboard()
duplicates = 0
for event in events:
    if not board.apply(event):
        duplicates += 1
print(f"total points: {board.total}")
print(f"duplicates ignored: {duplicates}")
