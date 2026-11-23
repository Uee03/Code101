from pydantic import ValidationError

from ownership import NotFound, OwnedTask, get_task_for, public_view
from secrets_hygiene import read_secret, tokens_match
from ssrf_guard import UnsafeUrl, validate_outbound_url
from validation import TaskCreate

ALLOWED_HOSTS = {"hooks.partner.example", "metadata.partner.example"}
ADDRESSES = {"hooks.partner.example": "8.8.8.8", "metadata.partner.example": "169.254.169.254"}


def fake_resolver(host: str, port: int) -> list:
    return [(0, 0, 0, "", (ADDRESSES[host], port))]


def main() -> None:
    target = validate_outbound_url("https://hooks.partner.example/notify", ALLOWED_HOSTS, fake_resolver)
    print(f"allowed: {target.host} -> {target.address}:{target.port}")
    for url in (
        "http://hooks.partner.example/notify",
        "https://evil.example/notify",
        "https://metadata.partner.example/latest",
    ):
        try:
            validate_outbound_url(url, ALLOWED_HOSTS, fake_resolver)
        except UnsafeUrl as error:
            print("refused:", error)

    try:
        TaskCreate(title="Pay invoice", owner="alice")
    except ValidationError:
        print("mass assignment refused: True")

    tasks = {1: OwnedTask(1, "alice", "Pay invoice")}
    print("alice sees:", public_view(get_task_for(tasks, 1, "alice")))
    try:
        get_task_for(tasks, 1, "bob")
    except NotFound as error:
        print("bob gets:", error)

    secret = read_secret("API_TOKEN", {"API_TOKEN": "s3cr3t-value"})
    print("secret repr:", secret)
    print("token check:", tokens_match("s3cr3t-value", secret), tokens_match("wrong", secret))


if __name__ == "__main__":
    main()
