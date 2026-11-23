from abc import ABC, abstractmethod


class Channel(ABC):
    @abstractmethod
    def send(self, message):
        ...


class AttachmentChannel(Channel):
    @abstractmethod
    def send_attachment(self, message, filename):
        ...


class EmailChannel(AttachmentChannel):
    def send(self, message):
        return f"Email: {message}"

    def send_attachment(self, message, filename):
        return f"Email: {message} [{filename}]"


class SmsChannel(Channel):
    def send(self, message):
        return f"SMS: {message}"


def send_report(channel: AttachmentChannel, message):
    print(channel.send(message))
    print(channel.send_attachment(message, "report.pdf"))


def send_text(channel: Channel, message):
    print(channel.send(message))


send_report(EmailChannel(), "Report ready")
send_text(SmsChannel(), "Report ready")
