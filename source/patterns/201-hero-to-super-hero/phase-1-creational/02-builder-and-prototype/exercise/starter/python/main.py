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
        # TODO 1: append the address to self._recipients and return self
        raise NotImplementedError("TODO 1")

    def with_subject(self, subject: str) -> "EmailBuilder":
        # TODO 2: set self._subject and return self
        raise NotImplementedError("TODO 2")

    def with_body(self, body: str) -> "EmailBuilder":
        # TODO 2: set self._body and return self
        raise NotImplementedError("TODO 2")

    def build(self) -> Email:
        # TODO 3: raise ValueError("an email needs at least one recipient") when there are no recipients,
        #         otherwise return Email(tuple(self._recipients), self._subject, self._body)
        raise NotImplementedError("TODO 3")


email = EmailBuilder().add_recipient("ana@example.com").add_recipient("bo@example.com").with_subject("Hello").with_body("Hi!").build()
print(email.describe())
try:
    EmailBuilder().with_subject("Lonely").build()
except ValueError as error:
    print(f"Rejected: {error}")
