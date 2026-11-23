import tempfile
import unittest
from pathlib import Path

from readiness_check import check_dockerfile, check_project

PROJECT = Path(__file__).resolve().parent.parent

GOOD_DOCKERFILE = """FROM python:3.14-slim AS build
FROM python:3.14-slim AS runtime
USER 10001
HEALTHCHECK CMD ["true"]
"""


def failed_checks(findings: list) -> list[str]:
    return [finding.check for finding in findings if not finding.ok]


class DockerfileChecks(unittest.TestCase):
    def test_a_good_dockerfile_passes(self) -> None:
        self.assertEqual(failed_checks(check_dockerfile(GOOD_DOCKERFILE)), [])

    def test_latest_and_untagged_images_fail(self) -> None:
        for image in ("python:latest", "python"):
            with self.subTest(image=image):
                findings = check_dockerfile(f"FROM {image}\nUSER 10001\nHEALTHCHECK CMD true\n")
                self.assertEqual(failed_checks(findings), ["base image is pinned"])

    def test_a_stage_name_is_not_an_unpinned_image(self) -> None:
        text = "FROM python:3.14-slim AS build\nFROM build\nUSER 10001\nHEALTHCHECK CMD true\n"
        self.assertEqual(failed_checks(check_dockerfile(text)), [])

    def test_root_and_missing_healthcheck_fail(self) -> None:
        findings = check_dockerfile("FROM python:3.14-slim\nUSER root\n")
        self.assertEqual(failed_checks(findings), ["runs as a non-root user", "has a HEALTHCHECK"])


class ProjectChecks(unittest.TestCase):
    def test_this_project_passes_its_own_checks(self) -> None:
        self.assertEqual(failed_checks(check_project(PROJECT)), [])

    def test_an_empty_folder_fails_everything_except_the_absence_of_env(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            findings = check_project(Path(folder))
        self.assertEqual(len(failed_checks(findings)), len(findings) - 1)


if __name__ == "__main__":
    unittest.main()
