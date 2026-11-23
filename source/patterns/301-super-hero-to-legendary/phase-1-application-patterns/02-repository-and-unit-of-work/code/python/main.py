from dataclasses import dataclass, replace


@dataclass(frozen=True)
class TaskItem:
    id: int
    title: str
    status: str
    assignee: str


class Database:
    """Stands in for the storage engine: a table plus a switch that simulates a failing write."""

    def __init__(self):
        self.tasks = {}
        self.fail_on_id = None

    def write(self, task):
        if task.id == self.fail_on_id:
            raise RuntimeError(f"write failed for task {task.id}")
        self.tasks[task.id] = task


class TaskRepository:
    def __init__(self, db, pending):
        self._db = db
        self._pending = pending

    def get(self, task_id):
        return self._pending.get(task_id) or self._db.tasks.get(task_id)

    def save(self, task):
        self._pending[task.id] = task

    def open_for(self, assignee):
        merged = {**self._db.tasks, **self._pending}
        found = [t for t in merged.values() if t.assignee == assignee and t.status != "done"]
        return sorted(found, key=lambda t: t.id)


class UnitOfWork:
    def __init__(self, db):
        self._db = db
        self._pending = {}
        self.tasks = TaskRepository(db, self._pending)

    def commit(self):
        backup = dict(self._db.tasks)
        try:
            for task in sorted(self._pending.values(), key=lambda t: t.id):
                self._db.write(task)
        except Exception:
            self._db.tasks = backup
            raise
        finally:
            self._pending.clear()


def reassign_open_tasks(uow, source, target):
    moved = 0
    for task in uow.tasks.open_for(source):
        uow.tasks.save(replace(task, assignee=target))
        moved += 1
    return moved


def main():
    db = Database()
    seed = UnitOfWork(db)
    seed.tasks.save(TaskItem(1, "Write ADR", "todo", "alice"))
    seed.tasks.save(TaskItem(2, "Review PR", "in_progress", "alice"))
    seed.tasks.save(TaskItem(3, "Ship release", "todo", "bob"))
    seed.commit()
    print(f"seeded {len(db.tasks)} tasks")

    db.fail_on_id = 2
    failing = UnitOfWork(db)
    reassign_open_tasks(failing, "alice", "dave")
    try:
        failing.commit()
    except RuntimeError as error:
        print(f"failed: {error}")
    print(f"after rollback: task 1 is still {db.tasks[1].assignee}")
    db.fail_on_id = None

    uow = UnitOfWork(db)
    reassign_open_tasks(uow, "alice", "carol")
    print(f"before commit: repo says {uow.tasks.get(1).assignee}, database says {db.tasks[1].assignee}")
    uow.commit()
    print(f"after commit: database says {db.tasks[1].assignee}")
    print(f"open tasks for carol: {[t.id for t in uow.tasks.open_for('carol')]}")


main()
