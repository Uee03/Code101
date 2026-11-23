"""Exercise: may this caller delete a team? It needs the scope tasks:admin AND the role admin."""


def has_scope(claims, scope):
    return False  # TODO rung 1: True when scope is one of the words in claims["scope"]


def has_role(claims, role):
    return False  # TODO rung 1: True when role is in claims["realm_access"]["roles"]


def may_delete_team(claims):
    return False  # TODO rung 2: both the scope tasks:admin and the role admin are needed


# TODO rung 3 (stretch): add status_for(claims): 401 without a token (claims is None),
# 204 when the delete is allowed, 403 otherwise. Then print the status after each answer.

CALLERS = {
    "alice with tasks:admin": {"scope": "openid tasks:read tasks:write tasks:admin", "realm_access": {"roles": ["admin"]}},
    "alice without tasks:admin": {"scope": "openid tasks:read tasks:write", "realm_access": {"roles": ["admin"]}},
    "bob with tasks:admin": {"scope": "openid tasks:read tasks:write tasks:admin", "realm_access": {"roles": ["member"]}},
    "bob": {"scope": "openid tasks:read tasks:write", "realm_access": {"roles": ["member"]}},
}
for name, claims in CALLERS.items():
    print(f"{name}: {'allowed' if may_delete_team(claims) else 'refused'}")
