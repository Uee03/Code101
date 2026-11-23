import inspect
import re
from dataclasses import dataclass
from datetime import date


# 1. God object: one class that needs everything, even for a simple report
class ConfigError(Exception):
    pass


class TaskManager:
    def __init__(self, smtp_host, db_path):
        if not smtp_host:
            raise ConfigError("smtp_host is required")
        self.db_path = db_path
        self.statuses = []

    def report(self):
        open_count = sum(1 for s in self.statuses if s != "done")
        return f"{open_count} open of {len(self.statuses)}"


def build_report(statuses):
    open_count = sum(1 for s in statuses if s != "done")
    return f"{open_count} open of {len(statuses)}"


# 2. Anemic model: rules live outside the data, so a second code path can skip them
@dataclass
class AnemicTask:
    title: str
    status: str = "todo"


def import_tasks(tasks):
    for task in tasks:
        task.status = "done"


class Task:
    def __init__(self, title, status="todo"):
        self.title = title
        self._status = status

    @property
    def status(self):
        return self._status

    def complete(self):
        if self._status == "cancelled":
            raise ValueError("a cancelled task cannot be completed")
        self._status = "done"


# 3. Golden hammer: a regular expression for a job a parser does better
def regex_accepts(text):
    return re.fullmatch(r"\d{4}-\d{2}-\d{2}", text) is not None


def parser_accepts(text):
    try:
        date.fromisoformat(text)
        return True
    except ValueError:
        return False


# 4. Service locator: dependencies hidden inside methods
class Locator:
    services = {}

    @classmethod
    def get(cls, name):
        if name not in cls.services:
            raise LookupError(f"{name} is not registered")
        return cls.services[name]


class LocatorReport:
    def run(self):
        return Locator.get("mailer").send("report")


class InjectedReport:
    def __init__(self, mailer):
        self.mailer = mailer

    def run(self):
        return self.mailer.send("report")


# 5. Singleton abuse: global state shared by every test
class Settings:
    _instance = None

    def __init__(self):
        self.currency = "EUR"

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = Settings()
        return cls._instance


def main():
    try:
        TaskManager(None, "tasks.db").report()
    except ConfigError as error:
        print(f"god object: cannot build a report: {error}")
    print(f"split: {build_report(['todo', 'done', 'todo'])}")

    legacy = AnemicTask("Old", "cancelled")
    import_tasks([legacy])
    print(f"anemic: importer completed a cancelled task, status={legacy.status}")
    rich = Task("Old", "cancelled")
    try:
        rich.complete()
    except ValueError as error:
        print(f"rich: rejected: {error}")

    print(f"hammer: regex accepts 2026-13-45: {regex_accepts('2026-13-45')}")
    print(f"right tool: date parser accepts 2026-13-45: {parser_accepts('2026-13-45')}")

    try:
        LocatorReport().run()
    except LookupError as error:
        print(f"service locator: found out at run time: {error}")
    needs = [name for name in inspect.signature(InjectedReport.__init__).parameters if name != "self"]
    print(f"constructor injection: dependencies visible: {', '.join(needs)}")

    Settings.instance().currency = "USD"
    print(f"singleton: second test sees {Settings.instance().currency} (leaked from the first)")
    print(f"injected: second test sees {Settings().currency}")


main()
