class StepCounter:
    def __init__(self, name):
        self.name = name
        self.steps = 0

    def walk(self, count):
        self.steps = self.steps + count


ada = StepCounter("Ada")
lin = StepCounter("Lin")
ada.walk(300)
ada.walk(200)
print(f"{ada.name}: {ada.steps}")
print(f"{lin.name}: {lin.steps}")
