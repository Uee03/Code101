from dataclasses import dataclass


class DomainError(Exception):
    pass


class ValidationError(Exception):
    pass


@dataclass(frozen=True)
class CreateTask:
    title: str
    assignee: str


@dataclass(frozen=True)
class CompleteTask:
    task_id: int


@dataclass(frozen=True)
class OpenTasksFor:
    assignee: str


@dataclass(frozen=True)
class Unknown:
    pass


class Mediator:
    def __init__(self):
        self._handlers = {}
        self._behaviors = []

    def register(self, request_type, handler):
        if request_type in self._handlers:
            raise ValueError(f"handler already registered for {request_type.__name__}")
        self._handlers[request_type] = handler

    def add_behavior(self, behavior):
        self._behaviors.append(behavior)

    def send(self, request):
        handler = self._handlers.get(type(request))
        if handler is None:
            raise LookupError(f"no handler for {type(request).__name__}")
        call = handler
        for behavior in reversed(self._behaviors):
            call = (lambda b, nxt: lambda r: b(r, nxt))(behavior, call)
        return call(request)


class OpenTasksView:
    """Read model: open task titles per assignee, fed by events."""

    def __init__(self):
        self.rows = {}
        self.pending = []
        self.paused = False

    def publish(self, event):
        self.pending.append(event)
        if not self.paused:
            self.catch_up()

    def catch_up(self):
        for kind, task_id, title, assignee in self.pending:
            rows = self.rows.setdefault(assignee, {})
            if kind == "created":
                rows[task_id] = title
            else:
                rows.pop(task_id, None)
        self.pending.clear()

    def titles_for(self, assignee):
        rows = self.rows.get(assignee, {})
        return [rows[task_id] for task_id in sorted(rows)]


def logging_behavior(request, next_handler):
    print(f"[log] {type(request).__name__}")
    return next_handler(request)


def validation_behavior(request, next_handler):
    if isinstance(request, CreateTask) and not request.title.strip():
        raise ValidationError("title is required")
    return next_handler(request)


def build_mediator(store, view):
    mediator = Mediator()
    mediator.add_behavior(logging_behavior)
    mediator.add_behavior(validation_behavior)

    def create_task(command):
        task_id = len(store) + 1
        store[task_id] = {"title": command.title, "status": "todo", "assignee": command.assignee}
        view.publish(("created", task_id, command.title, command.assignee))
        return task_id

    def complete_task(command):
        task = store.get(command.task_id)
        if task is None:
            raise DomainError(f"task {command.task_id} not found")
        if task["status"] == "done":
            raise DomainError(f"task {command.task_id} is already done")
        task["status"] = "done"
        view.publish(("completed", command.task_id, task["title"], task["assignee"]))

    def open_tasks_for(query):
        return view.titles_for(query.assignee)

    mediator.register(CreateTask, create_task)
    mediator.register(CompleteTask, complete_task)
    mediator.register(OpenTasksFor, open_tasks_for)
    return mediator


def attempt(action):
    try:
        message = action()
        if message is not None:
            print(message)
    except (ValidationError, DomainError, LookupError, ValueError) as error:
        print(f"rejected: {error}")


def main():
    store = {}
    view = OpenTasksView()
    mediator = build_mediator(store, view)

    attempt(lambda: f"created task {mediator.send(CreateTask('Write ADR', 'alice'))}")
    attempt(lambda: f"created task {mediator.send(CreateTask('Review PR', 'alice'))}")
    attempt(lambda: f"created task {mediator.send(CreateTask('', 'alice'))}")
    attempt(lambda: mediator.send(CompleteTask(1)) or "completed task 1")
    attempt(lambda: mediator.send(CompleteTask(1)) or "completed task 1")
    attempt(lambda: "open for alice: " + ", ".join(mediator.send(OpenTasksFor("alice"))))

    view.paused = True
    attempt(lambda: f"created task {mediator.send(CreateTask('Ship', 'alice'))}")
    attempt(lambda: "stale read: " + ", ".join(mediator.send(OpenTasksFor("alice"))))
    view.paused = False
    view.catch_up()
    attempt(lambda: "after catch-up: " + ", ".join(mediator.send(OpenTasksFor("alice"))))

    attempt(lambda: mediator.register(CreateTask, lambda command: 0))
    attempt(lambda: mediator.send(Unknown()))


main()
