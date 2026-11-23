"""Exercise: one more conformance check for POST /v1/tasks/{taskId}/complete.

Paste the function into scripts/conformance.py (above run()) and add
("complete task", check_complete_task) to the checks list after "audit log".
"""


def check_complete_task():
    task = need("task")
    current = api("GET", f"/v1/tasks/{task}")
    expect(current, 200)
    res = api("POST", f"/v1/tasks/{task}/complete", headers={"If-Match": current.headers["ETag"]})
    expect(res, 200)
    assert res.json["status"] == "done" and res.json["completedAt"], f"unexpected task {res.json}"
    return "task is done and has completedAt"
