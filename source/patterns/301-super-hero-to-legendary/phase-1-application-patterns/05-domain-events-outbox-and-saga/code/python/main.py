import copy
from contextlib import contextmanager


class EventBus:
    def __init__(self):
        self.handlers = {}

    def subscribe(self, event_type, handler):
        self.handlers.setdefault(event_type, []).append(handler)

    def publish(self, event):
        for handler in self.handlers.get(event["type"], []):
            handler(event)


class Idempotent:
    """Wraps a handler so a redelivered event is recognised and skipped."""

    def __init__(self, name, handler):
        self.name = name
        self.handler = handler
        self.seen = set()

    def __call__(self, event):
        if event["id"] in self.seen:
            print(f"{self.name}: skipped duplicate event {event['id']}")
            return
        self.seen.add(event["id"])
        self.handler(event)


class Store:
    def __init__(self):
        self.tasks = {}
        self.outbox = []
        self._next_event_id = 1

    def add_event(self, event_type, **data):
        event = {"id": self._next_event_id, "type": event_type, **data}
        self._next_event_id += 1
        self.outbox.append({"event": event, "published": False})

    @contextmanager
    def transaction(self):
        backup = copy.deepcopy((self.tasks, self.outbox, self._next_event_id))
        try:
            yield
        except Exception:
            self.tasks, self.outbox, self._next_event_id = backup
            raise


def complete_task(store, task_id, fail_before_commit=False):
    with store.transaction():
        task = store.tasks[task_id]
        task["status"] = "done"
        store.add_event("TaskCompleted", task_id=task_id, project=task["project"])
        if fail_before_commit:
            raise RuntimeError("crash before commit")


class Relay:
    def __init__(self, store, bus):
        self.store = store
        self.bus = bus

    def run_once(self, crash_after_publish=False):
        for row in self.store.outbox:
            if row["published"]:
                continue
            self.bus.publish(row["event"])
            if crash_after_publish:
                raise RuntimeError("crashed after publish, before marking")
            row["published"] = True


class Saga:
    def __init__(self, steps):
        self.steps = steps

    def run(self, context):
        done = []
        for name, action, compensate in self.steps:
            try:
                action(context)
                print(f"saga: {name} done")
                done.append((name, compensate))
            except RuntimeError as error:
                print(f"saga: {name} failed ({error})")
                for done_name, undo in reversed(done):
                    undo(context)
                    print(f"saga: {done_name} compensated")
                return False
        return True


def archive_saga():
    def mark_archived(context):
        if context["fail"]:
            raise RuntimeError("archive flag rejected")

    return Saga([
        ("freeze_tasks", lambda c: c.update(frozen=True), lambda c: c.update(frozen=False)),
        ("notify_members", lambda c: c["mails"].append("archiving"), lambda c: c["mails"].append("archive cancelled")),
        ("mark_archived", mark_archived, lambda c: None),
    ])


def show_saga(fail):
    context = {"fail": fail, "frozen": False, "mails": []}
    ok = archive_saga().run(context)
    print(f"saga result: {ok}, frozen={context['frozen']}, mails={', '.join(context['mails'])}")


def main():
    store = Store()
    store.tasks = {
        1: {"status": "todo", "project": "PLAT"},
        2: {"status": "todo", "project": "PLAT"},
        3: {"status": "todo", "project": "DOCS"},
    }
    bus = EventBus()

    def on_task_completed_progress(event):
        project = event["project"]
        in_project = [t for t in store.tasks.values() if t["project"] == project]
        if all(t["status"] == "done" for t in in_project):
            bus.publish({"id": 100, "type": "ProjectCompleted", "project": project})

    notify = Idempotent("notify", lambda e: print(f"notify: task {e['task_id']} completed (event {e['id']})"))
    progress = Idempotent("progress", on_task_completed_progress)
    bus.subscribe("TaskCompleted", notify)
    bus.subscribe("TaskCompleted", progress)
    bus.subscribe("ProjectCompleted", lambda e: print(f"lead: project {e['project']} completed"))
    relay = Relay(store, bus)

    try:
        complete_task(store, 1, fail_before_commit=True)
    except RuntimeError as error:
        print(f"failed: {error}")
    print(f"after failure: task 1 is {store.tasks[1]['status']}, outbox rows: {len(store.outbox)}")

    complete_task(store, 1)
    print(f"after commit: task 1 is {store.tasks[1]['status']}, outbox rows: {len(store.outbox)}")

    try:
        relay.run_once(crash_after_publish=True)
    except RuntimeError as error:
        print(f"relay: {error}")
    print(f"event 1 published flag: {store.outbox[0]['published']}")
    relay.run_once()
    print(f"event 1 published flag: {store.outbox[0]['published']}")

    complete_task(store, 2)
    relay.run_once()

    show_saga(fail=True)
    show_saga(fail=False)


main()
