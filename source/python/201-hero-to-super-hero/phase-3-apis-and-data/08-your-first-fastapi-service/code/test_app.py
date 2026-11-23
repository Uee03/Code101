import unittest

from fastapi.testclient import TestClient

from app import create_app


class ApiTests(unittest.TestCase):
    def test_create_read_and_output_filter(self) -> None:
        with TestClient(create_app()) as client:
            response = client.post("/notes", json={"title": " Read docs "})
            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.json(), {"id": 1, "title": "Read docs"})
            self.assertEqual(client.get("/notes/1").json(), response.json())

    def test_missing(self) -> None:
        with TestClient(create_app()) as client:
            self.assertEqual(client.get("/notes/1").status_code, 404)

    def test_invalid_input(self) -> None:
        with TestClient(create_app()) as client:
            for payload in ({"title": " "}, {"title": "x" * 121}, {"title": "A", "audit_label": "public"}):
                with self.subTest(payload=payload):
                    self.assertEqual(client.post("/notes", json=payload).status_code, 422)

    def test_factories_do_not_share_data(self) -> None:
        with TestClient(create_app()) as first, TestClient(create_app()) as second:
            first.post("/notes", json={"title": "Private to first app"})
            self.assertEqual(second.get("/notes/1").status_code, 404)
