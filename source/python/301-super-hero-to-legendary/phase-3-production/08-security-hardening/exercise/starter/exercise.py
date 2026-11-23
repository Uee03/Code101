from urllib.parse import urlsplit


def is_safe_redirect(target: str, allowed_hosts: set[str]) -> bool:
    # TODO 1: accept a path that starts with one "/" but not "//" and not "/\\" (browsers treat both as a host)
    # TODO 2: otherwise accept only an https URL whose hostname is in allowed_hosts
    # TODO 3: everything else (other schemes, empty host, relative text) is unsafe
    raise NotImplementedError


if __name__ == "__main__":
    allowed = {"app.example"}
    for target in ["/dashboard", "//evil.example/x", "https://app.example/home", "https://evil.example/", "javascript:alert(1)", "/\\evil.example"]:
        print(target, "->", is_safe_redirect(target, allowed))
