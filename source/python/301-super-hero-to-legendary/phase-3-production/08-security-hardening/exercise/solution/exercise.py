from urllib.parse import urlsplit


def is_safe_redirect(target: str, allowed_hosts: set[str]) -> bool:
    if target.startswith("/") and not target.startswith("//") and not target.startswith("/\\"):
        return True
    parts = urlsplit(target)
    return parts.scheme == "https" and (parts.hostname or "") in allowed_hosts


if __name__ == "__main__":
    allowed = {"app.example"}
    for target in ["/dashboard", "//evil.example/x", "https://app.example/home", "https://evil.example/", "javascript:alert(1)", "/\\evil.example"]:
        print(target, "->", is_safe_redirect(target, allowed))
