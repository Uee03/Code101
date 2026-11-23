import copy
import inspect


class DomainError(Exception):
    pass


class DomainEvent:
    def __init__(self, event_id, event_type, task_id, actor, team):
        self.id = event_id
        self.type = event_type
        self.task_id = task_id
        self.actor = actor
        self.team = team


class TaskItem:
    def __init__(self, task_id, title, status, assignee, team, due):
        self.id = task_id
        self.title = title
        self.status = status
        self.assignee = assignee
        self.team = team
        self.due = due
        self.events = []

    def complete(self, actor, is_lead):
        if self.status == "done":
            raise DomainError(f"task {self.id} is already done")
        if self.status == "cancelled":
            raise DomainError(f"task {self.id} is cancelled")
        if actor != self.assignee and not is_lead:
            raise DomainError(f"{actor} may not complete task {self.id}")
        self.status = "done"
        self.events.append(("TaskCompleted", actor))


class Database:
    def __init__(self, tasks):
        self.tasks = {t.id: t for t in tasks}
        self.leads = {"platform": "carol"}
        self.outbox = []


class TaskRepository:
    def __init__(self, uow):
        self._uow = uow

    def get(self, task_id):
        if task_id not in self._uow.loaded:
            original = self._uow.db.tasks.get(task_id)
            if original is None:
                return None
            self._uow.loaded[task_id] = copy.deepcopy(original)
        return self._uow.loaded[task_id]

    def overdue(self, today):
        found = [t for t in self._uow.db.tasks.values() if t.status in ("todo", "in_progress") and t.due < today]
        return sorted(found, key=lambda t: t.id)


class UnitOfWork:
    def __init__(self, db):
        self.db = db
        self.loaded = {}
        self.tasks = TaskRepository(self)

    def commit(self):
        for task in self.loaded.values():
            self.db.tasks[task.id] = task
            for event_type, actor in task.events:
                event = DomainEvent(len(self.db.outbox) + 1, event_type, task.id, actor, task.team)
                self.db.outbox.append({"event": event, "published": False})
            task.events = []
        self.loaded = {}


class Relay:
    def __init__(self, db, handlers):
        self.db = db
        self.handlers = handlers

    def run_once(self):
        published = 0
        for row in self.db.outbox:
            if row["published"]:
                continue
            for handler in self.handlers:
                handler(row["event"])
            row["published"] = True
            published += 1
        return published


class Notifier:
    def __init__(self, leads):
        self.leads = leads
        self.seen = set()

    def handle(self, event):
        if event.id in self.seen:
            return
        self.seen.add(event.id)
        print(f"notify lead {self.leads[event.team]}: task {event.task_id} completed by {event.actor} (event {event.id})")


def complete_task(uow, actor, task_id):
    task = uow.tasks.get(task_id)
    if task is None:
        raise DomainError(f"task {task_id} not found")
    task.complete(actor, uow.db.leads.get(task.team) == actor)
    uow.commit()
    return f"task {task_id} completed by {actor}"


def audited(handler, log):
    def run(actor, task_id):
        try:
            result = handler(actor, task_id)
        except DomainError:
            log.append(f"audit: {actor} complete_task {task_id} rejected")
            raise
        log.append(f"audit: {actor} complete_task {task_id} ok")
        return result

    return run


def main():
    db = Database([
        TaskItem(1, "Write ADR", "in_progress", "alice", "platform", "2026-03-05"),
        TaskItem(2, "Review PR", "todo", "alice", "platform", "2026-03-02"),
        TaskItem(3, "Ship release", "todo", "bob", "platform", "2026-03-20"),
        TaskItem(4, "Old chore", "cancelled", "bob", "platform", "2026-02-01"),
    ])
    audit_log = []
    notifier = Notifier(db.leads)
    relay = Relay(db, [notifier.handle])
    complete = audited(lambda actor, task_id: complete_task(UnitOfWork(db), actor, task_id), audit_log)

    for actor, task_id in [("alice", 1), ("bob", 2), ("carol", 2), ("alice", 1), ("bob", 4)]:
        try:
            print(complete(actor, task_id))
        except DomainError as error:
            print(f"rejected: {error}")

    first = relay.run_once()
    second = relay.run_once()
    print(f"relay published {first} events, then {second} on the second run")
    overdue = UnitOfWork(db).tasks.overdue("2026-03-25")
    print(f"overdue as of 2026-03-25: [{', '.join(str(t.id) for t in overdue)}]")
    for line in audit_log:
        print(line)

    own = [c for c in globals().values() if inspect.isclass(c) and c.__module__ == __name__]
    print(f"types in this design: {len(own)}")


main()
