"""Exercise 3: read token claims the way the API does (solution).

Run:  python claims.py
"""


def audiences(claims):
    aud = claims.get("aud", [])
    return [aud] if isinstance(aud, str) else list(aud)


def scopes(claims):
    return set(str(claims.get("scope", "")).split())


def allowed(claims, audience, needed_scope):
    return audience in audiences(claims) and needed_scope in scopes(claims)


if __name__ == "__main__":
    tokens = {
        "a": {"aud": "tasks-api", "scope": "openid tasks:read"},
        "b": {"aud": ["account", "tasks-api"], "scope": "openid tasks:read tasks:write"},
        "c": {"aud": "account", "scope": "tasks:read tasks:write"},
    }
    for name, claims in tokens.items():
        print(name, allowed(claims, "tasks-api", "tasks:write"))
