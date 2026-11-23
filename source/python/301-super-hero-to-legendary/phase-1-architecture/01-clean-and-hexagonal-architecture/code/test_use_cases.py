import unittest
from datetime import datetime, timezone
from pathlib import Path

from check_dependency_rule import imported_modules, violations
from taskapp.adapters.memory import FixedClock, InMemoryTaskRepository, RecordingNotifier
from taskapp.domain import DomainError, Task, TaskStatus
from taskapp.use_cases import CompleteTask, TaskNotFound

NOW = datetime(2026, 1, 15, 9, 30, tzinfo=timezone.utc)


class CompleteTaskTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repository = InMemoryTaskRepository([Task(1, "Write the report")])
        self.notifier = RecordingNotifier()
        self.complete = CompleteTask(self.repository, FixedClock(NOW), self.notifier)

    def test_completes_saves_and_notifies(self) -> None:
        done = self.complete(1)
        self.assertEqual(done.status, TaskStatus.DONE)
        self.assertEqual(done.completed_at, NOW)
        self.assertEqual(self.repository.get(1), done)
        self.assertEqual(self.notifier.completed, [1])

    def test_unknown_task_is_reported(self) -> None:
        with self.assertRaises(TaskNotFound):
            self.complete(99)
        self.assertEqual(self.notifier.completed, [])

    def test_completing_twice_breaks_the_domain_rule(self) -> None:
        self.complete(1)
        with self.assertRaises(DomainError):
            self.complete(1)
        self.assertEqual(self.notifier.completed, [1])


class DependencyRuleTests(unittest.TestCase):
    def test_the_package_obeys_the_rule(self) -> None:
        self.assertEqual(violations(Path(__file__).parent / "taskapp"), [])

    def test_the_checker_sees_a_bad_import(self) -> None:
        modules = imported_modules("import sqlite3\nfrom taskapp.adapters import memory\n")
        self.assertEqual(modules, {"sqlite3", "taskapp.adapters"})


if __name__ == "__main__":
    unittest.main()
