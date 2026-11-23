"""Exercise 3: read token claims the way the API does.

Finish the three functions. Run:  python claims.py
"""


def audiences(claims):
    # TODO 1: the aud claim is a string for one audience and a list for several. Always return a list.
    raise NotImplementedError


def scopes(claims):
    # TODO 2: the scope claim is ONE string with the scopes separated by spaces. Return a set of scopes.
    raise NotImplementedError


def allowed(claims, audience, needed_scope):
    # TODO 3: True only when the audience is listed AND the scope is granted
    raise NotImplementedError


if __name__ == "__main__":
    tokens = {
        "a": {"aud": "tasks-api", "scope": "openid tasks:read"},
        "b": {"aud": ["account", "tasks-api"], "scope": "openid tasks:read tasks:write"},
        "c": {"aud": "account", "scope": "tasks:read tasks:write"},
    }
    for name, claims in tokens.items():
        print(name, allowed(claims, "tasks-api", "tasks:write"))
