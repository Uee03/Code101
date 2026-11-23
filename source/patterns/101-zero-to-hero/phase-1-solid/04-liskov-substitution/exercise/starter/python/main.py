from abc import ABC, abstractmethod


class Channel(ABC):
    @abstractmethod
    def send(self, message):
        ...

    @abstractmethod
    def send_attachment(self, message, filename):
        ...


class EmailChannel(Channel):
    def send(self, message):
        return f"Email: {message}"

    def send_attachment(self, message, filename):
        return f"Email: {message} [{filename}]"


class SmsChannel(Channel):
    def send(self, message):
        return f"SMS: {message}"

    def send_attachment(self, message, filename):
        raise RuntimeError("SMS cannot carry attachments")


def send_report(channel, message):
    print(channel.send(message))
    print(channel.send_attachment(message, "report.pdf"))


# TODO 1: split Channel in two: Channel (only send) and AttachmentChannel(Channel) (adds send_attachment).
# TODO 2: EmailChannel becomes an AttachmentChannel. SmsChannel becomes a plain Channel and loses send_attachment.
# TODO 3: add send_text(channel, message) that only prints channel.send(message).
# TODO 4: change the last line so SMS uses send_text. The program must no longer crash.

send_report(EmailChannel(), "Report ready")
send_report(SmsChannel(), "Report ready")
