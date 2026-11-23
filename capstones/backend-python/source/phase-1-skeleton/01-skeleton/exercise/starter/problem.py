"""Exercise 1: problem details.

Finish problem_body() so it builds the same JSON object our API sends for an error (RFC 9457).
Run:  python problem.py
"""
import json

PROBLEM_BASE = "https://code101.example/problems/"

# status -> (last part of the type, title)
PROBLEMS = {
    404: ("not-found", "Not found"),
    409: ("conflict", "Conflict"),
    # TODO 1: add 412 with ("precondition-failed", "Precondition failed")
    # TODO 2: add 428 with ("precondition-required", "Precondition required")
}


def problem_body(status, detail, instance):
    # TODO 3: look the status up in PROBLEMS and return a dict with the keys
    # type, title, status, detail, instance (in this order); type is PROBLEM_BASE plus the slug
    raise NotImplementedError


if __name__ == "__main__":
    print(json.dumps(problem_body(412, "The task changed since you read it.", "/v1/tasks/1")))
    print(json.dumps(problem_body(428, "The If-Match header is required.", "/v1/tasks/1")))
