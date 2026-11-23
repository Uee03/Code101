class Counter:
    def __init__(self):
        self.value = 0


def hit(counter):
    counter.value += 1


def run_test(name):
    counter = Counter()
    hit(counter)
    print(f"{name}: counter is {counter.value}")


run_test("test one")
run_test("test two")
