from dataclasses import dataclass

SORTABLE = {"due": "due", "title": "title", "id": "id"}


@dataclass(frozen=True)
class TaskItem:
    id: int
    title: str
    status: str
    assignee: str
    due: str


class NotTranslatable(Exception):
    pass


class Spec:
    def matches(self, task):
        raise NotImplementedError

    def to_sql(self):
        raise NotImplementedError

    def __and__(self, other):
        return CombinedSpec("AND", self, other)

    def __or__(self, other):
        return CombinedSpec("OR", self, other)

    def __invert__(self):
        return NotSpec(self)


class AllSpec(Spec):
    def matches(self, task):
        return True

    def to_sql(self):
        return "1 = 1", []


class StatusSpec(Spec):
    def __init__(self, status):
        self.status = status

    def matches(self, task):
        return task.status == self.status

    def to_sql(self):
        return "status = ?", [self.status]


class AssigneeSpec(Spec):
    def __init__(self, assignee):
        self.assignee = assignee

    def matches(self, task):
        return task.assignee == self.assignee

    def to_sql(self):
        return "assignee = ?", [self.assignee]


class DueBeforeSpec(Spec):
    def __init__(self, day):
        self.day = day

    def matches(self, task):
        return task.due < self.day

    def to_sql(self):
        return "due < ?", [self.day]


class TitleSpec(Spec):
    def __init__(self, text):
        self.text = text.lower()

    def matches(self, task):
        return self.text in task.title.lower()

    def to_sql(self):
        return "lower(title) LIKE ?", [f"%{self.text}%"]


class PredicateSpec(Spec):
    def __init__(self, test):
        self.test = test

    def matches(self, task):
        return self.test(task)

    def to_sql(self):
        raise NotTranslatable("Predicate cannot be turned into SQL")


class CombinedSpec(Spec):
    def __init__(self, op, left, right):
        self.op = op
        self.left = left
        self.right = right

    def matches(self, task):
        if self.op == "AND":
            return self.left.matches(task) and self.right.matches(task)
        return self.left.matches(task) or self.right.matches(task)

    def to_sql(self):
        left_sql, left_params = self.left.to_sql()
        right_sql, right_params = self.right.to_sql()
        return f"({left_sql} {self.op} {right_sql})", left_params + right_params


class NotSpec(Spec):
    def __init__(self, inner):
        self.inner = inner

    def matches(self, task):
        return not self.inner.matches(task)

    def to_sql(self):
        sql, params = self.inner.to_sql()
        return f"NOT ({sql})", params


@dataclass
class TaskQuery:
    statuses: tuple = ()
    assignee: str | None = None
    due_before: str | None = None
    text: str | None = None
    sort: str = "due"
    limit: int = 10

    def to_spec(self):
        parts = []
        if self.statuses:
            status_spec = StatusSpec(self.statuses[0])
            for status in self.statuses[1:]:
                status_spec = status_spec | StatusSpec(status)
            parts.append(status_spec)
        if self.assignee:
            parts.append(AssigneeSpec(self.assignee))
        if self.due_before:
            parts.append(DueBeforeSpec(self.due_before))
        if self.text:
            parts.append(TitleSpec(self.text))
        if not parts:
            return AllSpec()
        spec = parts[0]
        for part in parts[1:]:
            spec = spec & part
        return spec

    def to_sql(self):
        column = SORTABLE.get(self.sort)
        if column is None:
            raise ValueError(f"cannot sort by {self.sort}")
        where_sql, params = self.to_spec().to_sql()
        limit = min(max(self.limit, 1), 100)
        sql = f"SELECT id, title, status, assignee, due FROM tasks WHERE {where_sql} ORDER BY {column} LIMIT ?"
        return sql, params + [limit]


def run_in_memory(tasks, query):
    spec = query.to_spec()
    found = [t for t in tasks if spec.matches(t)]
    found.sort(key=lambda t: getattr(t, SORTABLE[query.sort]))
    return found[: min(max(query.limit, 1), 100)]


def show(params):
    return "[" + ", ".join(f"'{p}'" if isinstance(p, str) else str(p) for p in params) + "]"


def ids(tasks):
    return "[" + ", ".join(str(t.id) for t in tasks) + "]"


def main():
    tasks = [
        TaskItem(1, "Write ADR", "todo", "alice", "2026-03-05"),
        TaskItem(2, "Review PR", "in_progress", "alice", "2026-03-02"),
        TaskItem(3, "Ship release", "todo", "bob", "2026-03-20"),
        TaskItem(4, "Fix login bug", "blocked", "carol", "2026-03-01"),
        TaskItem(5, "Plan sprint", "done", "alice", "2026-02-20"),
    ]

    query_a = TaskQuery(statuses=("todo", "in_progress"), assignee="alice", due_before="2026-03-10")
    sql, params = query_a.to_sql()
    print("query A sql:", sql)
    print("query A params:", show(params))
    print("query A result:", ids(run_in_memory(tasks, query_a)))

    query_b = TaskQuery(text="x; DROP TABLE tasks; --")
    sql, params = query_b.to_sql()
    print("query B sql:", sql)
    print("query B params:", show(params))
    print("query B result:", ids(run_in_memory(tasks, query_b)))

    overdue = DueBeforeSpec("2026-03-03") & ~StatusSpec("done")
    print("overdue sql:", overdue.to_sql()[0])
    print("overdue result:", ids([t for t in tasks if overdue.matches(t)]))

    long_titles = PredicateSpec(lambda t: len(t.title) > 10)
    print("long titles in memory:", ids([t for t in tasks if long_titles.matches(t)]))
    try:
        long_titles.to_sql()
    except NotTranslatable as error:
        print("long titles to sql:", error)

    try:
        TaskQuery(sort="due; DROP TABLE tasks").to_sql()
    except ValueError as error:
        print("bad sort:", error)


main()
