class Task:
    def __init__(self, id, assignee, status):
        self.id = id
        self.assignee = assignee
        self.status = status


class Spec:
    def matches(self, task):
        raise NotImplementedError

    def __and__(self, other):
        return AndSpec(self, other)

    def __invert__(self):
        return NotSpec(self)


class AndSpec(Spec):
    def __init__(self, left, right):
        self.left = left
        self.right = right

    def matches(self, task):
        return self.left.matches(task) and self.right.matches(task)


class NotSpec(Spec):
    def __init__(self, inner):
        self.inner = inner

    def matches(self, task):
        return not self.inner.matches(task)


class StatusSpec(Spec):
    def __init__(self, status):
        self.status = status

    def matches(self, task):
        return task.status == self.status


class AssigneeSpec(Spec):
    def __init__(self, assignee):
        self.assignee = assignee

    def matches(self, task):
        return task.assignee == self.assignee


tasks = [
    Task(1, "alice", "todo"),
    Task(2, "alice", "done"),
    Task(3, "bob", "todo"),
    Task(4, "alice", "in_progress"),
]


def ids(spec):
    return [t.id for t in tasks if spec.matches(t)]


print("alice open:", ids(AssigneeSpec("alice") & ~StatusSpec("done")))
print("not alice:", ids(~AssigneeSpec("alice")))
