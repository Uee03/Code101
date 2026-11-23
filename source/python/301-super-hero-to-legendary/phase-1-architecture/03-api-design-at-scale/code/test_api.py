import unittest

from fastapi.testclient import TestClient

from app import create_app


class BehaviourTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(create_app())

    def test_walking_every_page_visits_each_task_once(self) -> None:
        seen: list[int] = []
        cursor = None
        while True:
            params = {"limit": 3}
            if cursor:
                params["cursor"] = cursor
            body = self.client.get("/v1/tasks", params=params).json()
            seen += [item["id"] for item in body["items"]]
            cursor = body["next_cursor"]
            if cursor is None:
                break
        self.assertEqual(seen, [1, 2, 3, 4, 5, 6, 7])

    def test_a_cursor_not_issued_by_us_is_a_400_problem(self) -> None:
        response = self.client.get("/v1/tasks", params={"cursor": "not-a-cursor"})
        self.assertEqual(response.status_code, 400)
        self.assertTrue(response.headers["content-type"].startswith("application/problem+json"))
        self.assertEqual(response.json()["title"], "Invalid cursor")

    def test_a_limit_above_the_maximum_is_refused(self) -> None:
        self.assertEqual(self.client.get("/v1/tasks", params={"limit": 1000}).status_code, 422)

    def test_the_same_key_and_body_create_one_task(self) -> None:
        headers = {"Idempotency-Key": "key-0001-abc"}
        first = self.client.post("/v1/tasks", json={"title": "Pay invoice"}, headers=headers)
        second = self.client.post("/v1/tasks", json={"title": "Pay invoice"}, headers=headers)
        self.assertEqual(first.status_code, 201)
        self.assertEqual(second.json(), first.json())
        self.assertNotIn("idempotent-replay", first.headers)
        self.assertEqual(second.headers["idempotent-replay"], "true")
        ids = [item["id"] for item in self.client.get("/v1/tasks", params={"limit": 100}).json()["items"]]
        self.assertEqual(len(ids), 8)

    def test_the_same_key_with_another_body_is_422(self) -> None:
        headers = {"Idempotency-Key": "key-0002-abc"}
        self.client.post("/v1/tasks", json={"title": "Pay invoice"}, headers=headers)
        again = self.client.post("/v1/tasks", json={"title": "Something else"}, headers=headers)
        self.assertEqual(again.status_code, 422)
        self.assertEqual(again.json()["title"], "Idempotency key reused")

    def test_a_create_without_a_key_is_refused(self) -> None:
        self.assertEqual(self.client.post("/v1/tasks", json={"title": "No key"}).status_code, 422)

    def test_v2_changes_the_shape_and_v1_does_not(self) -> None:
        v2 = self.client.get("/v2/tasks", params={"limit": 2}).json()["items"]
        v1 = self.client.get("/v1/tasks", params={"limit": 2}).json()["items"]
        self.assertEqual(v2[1], {"id": 2, "title": "Seed task 2", "status": "done"})
        self.assertEqual(v1[1], {"id": 2, "title": "Seed task 2", "done": True})

    def test_v1_announces_its_sunset_and_successor(self) -> None:
        response = self.client.get("/v1/tasks")
        self.assertIn("sunset", response.headers)
        self.assertIn("successor-version", response.headers["link"])


class ContractTests(unittest.TestCase):
    V1_CONSUMER_NEEDS = {"id", "title", "done"}

    def setUp(self) -> None:
        self.schema = create_app().openapi()

    def test_v1_task_keeps_the_fields_consumers_use(self) -> None:
        properties = set(self.schema["components"]["schemas"]["TaskV1"]["properties"])
        self.assertTrue(self.V1_CONSUMER_NEEDS <= properties)

    def test_v1_operations_still_exist(self) -> None:
        self.assertEqual(set(self.schema["paths"]["/v1/tasks"]), {"get", "post"})

    def test_pagination_parameters_are_documented(self) -> None:
        parameters = self.schema["paths"]["/v1/tasks"]["get"]["parameters"]
        self.assertEqual({parameter["name"] for parameter in parameters}, {"limit", "cursor"})


if __name__ == "__main__":
    unittest.main()
