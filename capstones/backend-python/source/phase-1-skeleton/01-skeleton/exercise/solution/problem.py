"""Exercise 1: problem details (solution).

Run:  python problem.py
"""
import json

PROBLEM_BASE = "https://code101.example/problems/"

# status -> (last part of the type, title)
PROBLEMS = {
    404: ("not-found", "Not found"),
    409: ("conflict", "Conflict"),
    412: ("precondition-failed", "Precondition failed"),
    428: ("precondition-required", "Precondition required"),
}


def problem_body(status, detail, instance):
    slug, title = PROBLEMS[status]
    return {
        "type": PROBLEM_BASE + slug,
        "title": title,
        "status": status,
        "detail": detail,
        "instance": instance,
    }


if __name__ == "__main__":
    print(json.dumps(problem_body(412, "The task changed since you read it.", "/v1/tasks/1")))
    print(json.dumps(problem_body(428, "The If-Match header is required.", "/v1/tasks/1")))
