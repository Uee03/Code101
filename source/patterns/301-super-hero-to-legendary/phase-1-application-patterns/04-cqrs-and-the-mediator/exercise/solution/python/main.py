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
        for behavior in reversed(self.behaviors):
            call = (lambda b, nxt: lambda r: b(r, nxt))(behavior, call)
        return call(request)


seen = []


def counting(request, next_handler):
    seen.append(type(request).__name__)
    return next_handler(request)


def shout(request, next_handler):
    return next_handler(request).upper()


mediator = Mediator()
mediator.register(Greet, lambda request: f"hello {request.name}")
mediator.add_behavior(counting)
mediator.add_behavior(shout)
print(mediator.send(Greet("ana")))
print(f"requests seen: {len(seen)}")
