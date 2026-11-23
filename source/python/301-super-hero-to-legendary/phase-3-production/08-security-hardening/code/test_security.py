import tempfile
import unittest
from pathlib import Path

from pydantic import ValidationError

from ownership import NotFound, OwnedTask, get_task_for, public_view
from secrets_hygiene import Secret, read_secret, tokens_match
from ssrf_guard import UnsafeUrl, is_public, validate_outbound_url
from validation import TaskCreate

ALLOWED = {"hooks.partner.example"}


def resolving_to(*addresses: str):
    def resolver(host: str, port: int) -> list:
        return [(0, 0, 0, "", (address, port)) for address in addresses]

    return resolver


class SsrfGuardTests(unittest.TestCase):
    def test_a_public_address_on_the_allow_list_is_accepted(self) -> None:
        target = validate_outbound_url("https://hooks.partner.example/x", ALLOWED, resolving_to("8.8.8.8"))
        self.assertEqual((target.host, target.port, target.address), ("hooks.partner.example", 443, "8.8.8.8"))

    def test_non_public_addresses_are_never_public(self) -> None:
        for address in ("127.0.0.1", "10.0.0.5", "169.254.169.254", "100.64.0.1", "::1", "224.0.0.1", "::ffff:127.0.0.1"):
            with self.subTest(address=address):
                self.assertFalse(is_public(address))

    def test_a_host_that_resolves_to_a_private_address_is_refused(self) -> None:
        with self.assertRaises(UnsafeUrl):
            validate_outbound_url("https://hooks.partner.example/x", ALLOWED, resolving_to("10.0.0.5"))

    def test_one_bad_address_among_good_ones_refuses_the_url(self) -> None:
        with self.assertRaises(UnsafeUrl):
            validate_outbound_url(
                "https://hooks.partner.example/x", ALLOWED, resolving_to("8.8.8.8", "127.0.0.1")
            )

    def test_other_unsafe_forms_are_refused(self) -> None:
        resolver = resolving_to("8.8.8.8")
        for url in (
            "http://hooks.partner.example/x",
            "https://user:pw@hooks.partner.example/x",
            "https://evil.example/x",
            "https://127.0.0.1/x",
            "https://hooks.partner.example:abc/x",
            "file:///etc/passwd",
        ):
            with self.subTest(url=url):
                with self.assertRaises(UnsafeUrl):
                    validate_outbound_url(url, ALLOWED, resolver)


class ValidationTests(unittest.TestCase):
    def test_unknown_fields_are_refused(self) -> None:
        with self.assertRaises(ValidationError):
            TaskCreate(title="Pay", owner="alice")

    def test_limits_and_strict_types_are_enforced(self) -> None:
        for data in ({"title": ""}, {"title": "x" * 81}, {"title": "   "}, {"title": "ok", "due_in_days": "7"}, {"title": "ok", "due_in_days": 366}):
            with self.subTest(data=data):
                with self.assertRaises(ValidationError):
                    TaskCreate(**data)

    def test_a_valid_body_gets_its_default(self) -> None:
        self.assertEqual(TaskCreate(title="  Pay  ").title, "Pay")
        self.assertEqual(TaskCreate(title="Pay").due_in_days, 7)


class OwnershipTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tasks = {1: OwnedTask(1, "alice", "Pay invoice")}

    def test_the_owner_can_read_the_task(self) -> None:
        self.assertEqual(get_task_for(self.tasks, 1, "alice").title, "Pay invoice")

    def test_another_user_gets_the_same_error_as_a_missing_task(self) -> None:
        with self.assertRaises(NotFound) as other_user:
            get_task_for(self.tasks, 1, "bob")
        with self.assertRaises(NotFound) as missing:
            get_task_for(self.tasks, 2, "bob")
        self.assertEqual(str(other_user.exception), str(missing.exception))

    def test_the_public_view_hides_the_owner(self) -> None:
        self.assertEqual(public_view(self.tasks[1]), {"id": 1, "title": "Pay invoice"})


class SecretTests(unittest.TestCase):
    def test_a_secret_does_not_print_its_value(self) -> None:
        secret = Secret("s3cr3t-value")
        self.assertNotIn("s3cr3t", repr(secret) + str(secret) + f"{secret}")

    def test_a_secret_can_come_from_a_file(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "token"
            path.write_text("from-file\n", encoding="utf-8")
            secret = read_secret("API_TOKEN", {"API_TOKEN_FILE": str(path)})
        self.assertEqual(secret.reveal(), "from-file")

    def test_a_missing_secret_stops_start_up(self) -> None:
        with self.assertRaises(RuntimeError):
            read_secret("API_TOKEN", {})

    def test_token_comparison(self) -> None:
        secret = Secret("abc")
        self.assertTrue(tokens_match("abc", secret))
        self.assertFalse(tokens_match("abd", secret))


if __name__ == "__main__":
    unittest.main()
