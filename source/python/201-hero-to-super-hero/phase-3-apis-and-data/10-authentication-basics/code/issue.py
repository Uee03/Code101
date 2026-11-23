import argparse

from security import issue_token
from settings import Settings


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trusted local issuer, not a login endpoint")
    parser.add_argument("subject")
    args = parser.parse_args()
    settings = Settings()
    print(issue_token(args.subject, settings.jwt_secret.get_secret_value()))
