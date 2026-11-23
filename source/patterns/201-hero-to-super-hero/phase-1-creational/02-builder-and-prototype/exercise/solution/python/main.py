from dataclasses import dataclass


@dataclass(frozen=True)
class Email:
    recipients: tuple
    subject: str
    body: str

    def describe(self) -> str:
        return f"To: {', '.join(self.recipients)} | Subject: {self.subject} | Body: {self.body}"


class EmailBuilder:
    def __init__(self) -> None:
        self._recipients: list = []
        self._subject = "(no subject)"
        self._body = ""

    def add_recipient(self, address: str) -> "EmailBuilder":
        self._recipients.append(address)
        return self

    def with_subject(self, subject: str) -> "EmailBuilder":
        self._subject = subject
        return self

    def with_body(self, body: str) -> "EmailBuilder":
        self._body = body
        return self

    def build(self) -> Email:
        if not self._recipients:
            raise ValueError("an email needs at least one recipient")
        return Email(tuple(self._recipients), self._subject, self._body)


email = EmailBuilder().add_recipient("ana@example.com").add_recipient("bo@example.com").with_subject("Hello").with_body("Hi!").build()
print(email.describe())
try:
    EmailBuilder().with_subject("Lonely").build()
except ValueError as error:
    print(f"Rejected: {error}")
