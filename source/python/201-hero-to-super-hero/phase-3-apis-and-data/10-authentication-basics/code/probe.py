from secrets import token_hex

from fastapi.testclient import TestClient

from app import create_app
from security import issue_token, password_hash
from settings import Settings


if __name__ == "__main__":
    secret = token_hex(32)
    settings = Settings(jwt_secret=secret, _env_file=None)
    hashed = password_hash.hash("demonstration-only")
    print("password verified:", password_hash.verify("demonstration-only", hashed))
    with TestClient(create_app(settings)) as client:
        print("missing bearer:", client.get("/me").status_code)
        token = issue_token("ada", secret)
        response = client.get("/me", headers={"Authorization": f"Bearer {token}"})
        print(response.status_code, response.json())
