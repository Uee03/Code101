"""Exercise: one more conformance check for POST /v1/tasks/{taskId}/complete.

Paste the function into scripts/conformance.py (above run()) and add
("complete task", check_complete_task) to the checks list after "audit log".
"""


def check_complete_task():
    # TODO 1: read the task id with need("task") and fetch the task with api("GET", ...)
    # TODO 2: POST to /v1/tasks/{id}/complete with the If-Match header set to the ETag you just read
    # TODO 3: expect HTTP 200, status "done" and a non-empty completedAt
    # TODO 4: return a short sentence, as the other checks do
    raise NotImplementedError
