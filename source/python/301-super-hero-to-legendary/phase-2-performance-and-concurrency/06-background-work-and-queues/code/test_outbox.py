import sqlite3
import unittest

import outbox
from main import Mailer
from outbox import Message, complete_task, connect, count
from worker import run_once


def connection_with_task() -> sqlite3.Connection:
    connection = connect()
    connection.execute("INSERT INTO tasks (id, title) VALUES (1, 'Write the report')")
    connection.commit()
    return connection


def always_fails(message: Message) -> None:
    raise ConnectionError("down")


class AtomicityTests(unittest.TestCase):
    def test_the_task_and_the_message_are_written_together(self) -> None:
        connection = connection_with_task()
        complete_task(connection, 1, now=0.0)
        done = connection.execute("SELECT done FROM tasks WHERE id = 1").fetchone()[0]
        self.assertEqual((done, count(connection)), (1, 1))

    def test_a_refused_change_writes_no_message(self) -> None:
        connection = connection_with_task()
        with self.assertRaises(LookupError):
            complete_task(connection, 99, now=0.0)
        self.assertEqual(count(connection), 0)

    def test_if_the_message_cannot_be_written_the_task_stays_open(self) -> None:
        connection = connection_with_task()
        connection.execute("DROP TABLE outbox")
        with self.assertRaises(sqlite3.OperationalError):
            complete_task(connection, 1, now=0.0)
        done = connection.execute("SELECT done FROM tasks WHERE id = 1").fetchone()[0]
        self.assertEqual(done, 0)


class RetryTests(unittest.TestCase):
    def test_backoff_doubles_and_is_capped(self) -> None:
        self.assertEqual([outbox.backoff(n) for n in (1, 2, 3)], [1.0, 2.0, 4.0])
        self.assertEqual(outbox.backoff(10), 60.0)

    def test_a_flaky_receiver_succeeds_on_the_third_attempt(self) -> None:
        connection = connection_with_task()
        complete_task(connection, 1, now=0.0)
        mailer = Mailer(fail_first=2)

        def handler(message: Message) -> None:
            mailer.send(f"outbox-{message.id}", "done")

        results = [run_once(connection, handler, now) for now in (0.0, 0.5, 1.0, 3.0)]
        self.assertEqual([r["retry"] for r in results], [1, 0, 1, 0])
        self.assertEqual(results[-1]["done"], 1)
        self.assertEqual(count(connection, "done"), 1)

    def test_a_message_that_always_fails_ends_in_the_dead_letter_state(self) -> None:
        connection = connection_with_task()
        complete_task(connection, 1, now=0.0)
        for now in (0.0, 1.0, 3.0):
            run_once(connection, always_fails, now, max_attempts=3)
        self.assertEqual(count(connection, "dead"), 1)
        self.assertEqual(run_once(connection, always_fails, 100.0), {"done": 0, "retry": 0, "dead": 0})


class IdempotentReceiverTests(unittest.TestCase):
    def test_delivering_the_same_message_twice_has_one_effect(self) -> None:
        mailer = Mailer(fail_first=0)
        mailer.send("outbox-1", "task 1 done")
        mailer.send("outbox-1", "task 1 done")
        self.assertEqual(len(mailer.sent), 1)


if __name__ == "__main__":
    unittest.main()
