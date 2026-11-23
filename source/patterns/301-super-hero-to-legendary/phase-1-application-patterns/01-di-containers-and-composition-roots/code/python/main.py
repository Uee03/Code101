from abc import ABC, abstractmethod


class Container:
    def __init__(self):
        self._factories = {}
        self._lifetimes = {}
        self._singletons = {}

    def register(self, key, factory, lifetime="transient"):
        self._factories[key] = factory
        self._lifetimes[key] = lifetime

    def resolve(self, key, scope=None, _path=()):
        if key in _path:
            chain = " -> ".join(k.__name__ for k in _path + (key,))
            raise RuntimeError(f"circular dependency: {chain}")
        if key not in self._factories:
            raise KeyError(f"not registered: {key.__name__}")
        lifetime = self._lifetimes[key]
        holder = next((p for p in _path if self._lifetimes[p] == "singleton"), None)
        if lifetime == "scoped" and holder is not None:
            raise RuntimeError(f"captive dependency: singleton {holder.__name__} would keep scoped {key.__name__} alive")
        if lifetime == "scoped" and scope is None:
            raise RuntimeError(f"{key.__name__} is scoped: resolve it inside a scope")
        cache = self._singletons if lifetime == "singleton" else scope
        if lifetime != "transient" and key in cache:
            return cache[key]
        instance = self._factories[key](lambda dep: self.resolve(dep, scope, _path + (key,)))
        if lifetime != "transient":
            cache[key] = instance
        return instance

    def validate(self):
        problems = []
        for key in self._factories:
            try:
                self.resolve(key, {})
            except (RuntimeError, KeyError) as error:
                problems.append(f"{key.__name__}: {error}")
        return problems


class Clock(ABC):
    @abstractmethod
    def today(self):
        ...


class FixedClock(Clock):
    def __init__(self, day):
        self._day = day

    def today(self):
        return self._day


class Mailer(ABC):
    @abstractmethod
    def send(self, text):
        ...


class ConsoleMailer(Mailer):
    def send(self, text):
        print(f"mail: {text}")


class TaskRepository(ABC):
    @abstractmethod
    def add(self, title):
        ...


class InMemoryTaskRepository(TaskRepository):
    def __init__(self):
        self._titles = []

    def add(self, title):
        self._titles.append(title)
        return len(self._titles)


class RequestContext:
    def __init__(self, user):
        self.user = user


class TaskService:
    def __init__(self, repo, clock, mailer, context):
        self._repo = repo
        self._clock = clock
        self._mailer = mailer
        self._context = context

    def create(self, title):
        task_id = self._repo.add(title)
        self._mailer.send(f"task {task_id} created")
        return f"{self._context.user} created task {task_id} '{title}' on {self._clock.today()}"


class ReportCache:
    def __init__(self, context):
        self.context = context


class Alpha:
    def __init__(self, beta):
        self.beta = beta


class Beta:
    def __init__(self, alpha):
        self.alpha = alpha


def build_container():
    container = Container()
    container.register(Clock, lambda get: FixedClock("2026-03-01"), "singleton")
    container.register(TaskRepository, lambda get: InMemoryTaskRepository(), "singleton")
    container.register(Mailer, lambda get: ConsoleMailer())
    container.register(RequestContext, lambda get: RequestContext("alice"), "scoped")
    container.register(
        TaskService,
        lambda get: TaskService(get(TaskRepository), get(Clock), get(Mailer), get(RequestContext)),
    )
    return container


def main():
    container = build_container()
    problems = container.validate()
    print(f"validate: {len(problems)} problem(s)")

    for number in (1, 2):
        service = container.resolve(TaskService, {})
        print(service.create(f"Write ADR {number}"))

    scope_a, scope_b = {}, {}
    print("singleton repo shared:", container.resolve(TaskRepository) is container.resolve(TaskRepository))
    print("transient mailer shared:", container.resolve(Mailer) is container.resolve(Mailer))
    print("scoped context shared in one scope:", container.resolve(RequestContext, scope_a) is container.resolve(RequestContext, scope_a))
    print("scoped context shared across scopes:", container.resolve(RequestContext, scope_a) is container.resolve(RequestContext, scope_b))

    broken = build_container()
    broken.register(ReportCache, lambda get: ReportCache(get(RequestContext)), "singleton")
    print("captive: container refused to build:", len(broken.validate()) > 0)

    loop = Container()
    loop.register(Alpha, lambda get: Alpha(get(Beta)))
    loop.register(Beta, lambda get: Beta(get(Alpha)))
    print("cycle: container refused to build:", len(loop.validate()) > 0)


main()
