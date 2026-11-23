from outbox import Message, complete_task, connect, count
from worker import run_once


class Mailer:
    """A receiver that deduplicates by idempotency key, like many payment and email APIs."""

    def __init__(self, fail_first: int) -> None:
        self.fail_first = fail_first
        self.attempts = 0
        self.sent: dict[str, str] = {}

    def send(self, idempotency_key: str, text: str) -> None:
        self.attempts += 1
        if self.attempts <= self.fail_first:
            raise ConnectionError("mail provider unavailable")
        self.sent.setdefault(idempotency_key, text)


def main() -> None:
    connection = connect()
    connection.execute("INSERT INTO tasks (id, title) VALUES (1, 'Write the report')")
    connection.commit()
    complete_task(connection, 1, now=0.0)
    print("outbox rows after complete:", count(connection))
    try:
        complete_task(connection, 1, now=0.0)
    except LookupError as error:
        print("second complete refused:", error)
    print("outbox rows still:", count(connection))

    mailer = Mailer(fail_first=2)

    def handler(message: Message) -> None:
        mailer.send(f"outbox-{message.id}", f"task {message.payload['task_id']} done")

    for now in (0.0, 0.5, 1.0, 3.0):
        print(f"t={now}", run_once(connection, handler, now))
    print("emails sent:", mailer.sent)
    print("mailer attempts:", mailer.attempts)
    mailer.send("outbox-1", "task 1 done")
    print("replayed delivery, emails sent:", len(mailer.sent))


if __name__ == "__main__":
    main()
