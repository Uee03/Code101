import unittest

from fastapi.testclient import TestClient

from taskservice import __version__
from taskservice.app import create_app


class ProbeTests(unittest.TestCase):
    def test_liveness_does_not_depend_on_anything(self) -> None:
        client = TestClient(create_app(lambda: False))
        self.assertEqual(client.get("/healthz").json(), {"status": "alive"})

    def test_readiness_is_200_when_the_dependency_is_up(self) -> None:
        client = TestClient(create_app(lambda: True))
        response = client.get("/readyz")
        self.assertEqual((response.status_code, response.json()), (200, {"status": "ready"}))

    def test_readiness_is_503_when_the_dependency_is_down(self) -> None:
        client = TestClient(create_app(lambda: False))
        response = client.get("/readyz")
        self.assertEqual((response.status_code, response.json()), (503, {"status": "not ready"}))

    def test_the_running_service_reports_the_packaged_version(self) -> None:
        client = TestClient(create_app())
        self.assertEqual(client.get("/version").json(), {"version": __version__})


if __name__ == "__main__":
    unittest.main()
