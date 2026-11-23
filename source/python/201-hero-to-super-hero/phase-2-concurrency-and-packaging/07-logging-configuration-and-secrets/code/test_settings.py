import os
import unittest
from unittest.mock import patch

from pydantic import ValidationError

from main import report_startup
from settings import Settings


class SettingsTests(unittest.TestCase):
    def test_environment_conversion_and_redaction(self) -> None:
        with patch.dict(os.environ, {"NOTES_API_KEY": "test-only", "NOTES_BATCH_SIZE": "7"}, clear=True):
            settings = Settings(_env_file=None)
        self.assertEqual(settings.batch_size, 7)
        self.assertEqual(str(settings.api_key), "**********")

    def test_missing_secret(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ValidationError):
                Settings(_env_file=None)

    def test_invalid_batch_size(self) -> None:
        with patch.dict(os.environ, {"NOTES_API_KEY": "test-only", "NOTES_BATCH_SIZE": "0"}, clear=True):
            with self.assertRaises(ValidationError):
                Settings(_env_file=None)

    def test_log_does_not_contain_secret(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            settings = Settings(api_key="test-only", batch_size=10, _env_file=None)
        with self.assertLogs("notes", level="INFO") as captured:
            report_startup(settings)
        self.assertEqual(captured.output, ["INFO:notes:startup batch_size=10"])
