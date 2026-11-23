class DomainError(Exception):
    pass


LEAD = "carol"


class TaskItem:
    def __init__(self, task_id, assignee):
        self.id = task_id
        self.assignee = assignee

    def reassign(self, new_assignee, actor):
        # TODO 1: raise DomainError(f"{actor} is not the lead") unless actor is LEAD.
        # TODO 2: raise DomainError(f"task {self.id} already belongs to {new_assignee}") when nothing would change.
        # TODO 3: otherwise set the new assignee.
        raise NotImplementedError


task = TaskItem(1, "alice")
for actor, new_assignee in [("carol", "bob"), ("alice", "dave"), ("carol", "bob")]:
    try:
        task.reassign(new_assignee, actor)
        print(f"task {task.id} now belongs to {task.assignee}")
    except DomainError as error:
        print(f"rejected: {error}")
