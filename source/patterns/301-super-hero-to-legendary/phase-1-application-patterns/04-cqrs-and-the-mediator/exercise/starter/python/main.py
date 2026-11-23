from dataclasses import dataclass


@dataclass(frozen=True)
class Greet:
    name: str


class Mediator:
    def __init__(self):
        self.handlers = {}
        self.behaviors = []

    def register(self, request_type, handler):
        self.handlers[request_type] = handler

    def add_behavior(self, behavior):
        self.behaviors.append(behavior)

    def send(self, request):
        call = self.handlers[type(request)]
        # TODO 1: wrap call with every behavior so that behaviors[0] runs first and the handler runs last.
        #         A behavior is a function (request, next_handler) that calls next_handler(request).
        return call(request)


seen = []


def counting(request, next_handler):
    seen.append(type(request).__name__)
    return next_handler(request)


# TODO 2: write shout(request, next_handler): call next_handler(request) and return the result in upper case.

mediator = Mediator()
mediator.register(Greet, lambda request: f"hello {request.name}")
mediator.add_behavior(counting)
# TODO 3: add the shout behavior to the mediator.
print(mediator.send(Greet("ana")))
print(f"requests seen: {len(seen)}")
