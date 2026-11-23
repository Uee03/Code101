class Task:
    def __init__(self, task_id, title):
        self.id = task_id
        self.title = title
        self.done = False

    def complete(self):
        if self.done:
            raise ValueError(f"task {self.id} is already done")
        self.done = True
