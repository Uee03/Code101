from datetime import UTC, datetime, timedelta
from secrets import token_hex
import unittest

import jwt
from fastapi.testclient import TestClient
from jwt.exceptions import InvalidTokenError

from app import create_app
from security import AUDIENCE, ISSUER, issue_token, password_hash, validate_token
from settings import Settings


class SecurityTests(unittest.TestCase):
    def test_salted_password_hashes(self) -> None:
        first = password_hash.hash("test-only")
        second = password_hash.hash("test-only")
        self.assertNotEqual(first, second)
        self.assertTrue(password_hash.verify("test-only", first))
        self.assertFalse(password_hash.verify("wrong", first))

    def test_valid_and_wrong_key(self) -> None:
        secret = token_hex(32)
        token = issue_token("ada", secret)
        self.assertEqual(validate_token(token, secret), "ada")
        with self.assertRaises(InvalidTokenError):
            validate_token(token, token_hex(32))

    def test_expired(self) -> None:
        secret = token_hex(32)
        token = issue_token("ada", secret, now=datetime(2000, 1, 1, tzinfo=UTC))
        with self.assertRaises(InvalidTokenError):
            validate_token(token, secret)

    def test_required_claims_and_trust_boundary(self) -> None:
        secret = token_hex(32)
        base = {"sub": "ada", "iss": ISSUER, "aud": AUDIENCE, "exp": datetime.now(UTC) + timedelta(minutes=5)}
        cases = [dict(base, iss="elsewhere"), dict(base, aud="another-api"), dict(base, sub=" ")]
        missing = base.copy()
        del missing["exp"]
        cases.append(missing)
        for claims in cases:
            with self.subTest(claims=claims), self.assertRaises(InvalidTokenError):
                validate_token(jwt.encode(claims, secret, algorithm="HS256"), secret)
        with self.assertRaises(InvalidTokenError):
            validate_token(jwt.encode(base, "", algorithm="none"), secret)

    def test_missing_and_malformed_bearer(self) -> None:
        settings = Settings(jwt_secret=token_hex(32), _env_file=None)
        with TestClient(create_app(settings)) as client:
            for headers in ({}, {"Authorization": "Bearer broken"}, {"Authorization": "Basic abc"}):
                response = client.get("/me", headers=headers)
                self.assertEqual(response.status_code, 401)
                self.assertEqual(response.headers["www-authenticate"], "Bearer")
