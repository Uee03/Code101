from pathlib import Path
from secrets import token_hex


if __name__ == "__main__":
    content = Path(".env.example").read_text(encoding="utf-8")
    content = content.replace("replace-db-password", token_hex(32))
    content = content.replace("replace-jwt-secret", token_hex(32))
    with Path(".env").open("x", encoding="utf-8") as file:
        file.write(content)
    print("Created .env; keep it private.")
