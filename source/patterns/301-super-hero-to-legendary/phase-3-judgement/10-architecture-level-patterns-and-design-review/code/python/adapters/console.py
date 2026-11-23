from domain.task import Task


def render(task: Task) -> str:
    return f"completed: {task.title} is done={task.done}"
