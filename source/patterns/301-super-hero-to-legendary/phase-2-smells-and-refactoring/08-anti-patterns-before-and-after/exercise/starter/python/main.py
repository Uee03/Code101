class Counter:
    _instance = None

    def __init__(self):
        self.value = 0

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = Counter()
        return cls._instance


def hit():
    # TODO 1: receive a Counter as a parameter, increment that counter and stop using Counter.instance().
    Counter.instance().value += 1


def run_test(name):
    # TODO 2: create a new Counter here and pass it to hit.
    hit()
    # TODO 3: print the value of the counter you created instead of the shared one.
    print(f"{name}: counter is {Counter.instance().value}")


run_test("test one")
run_test("test two")
