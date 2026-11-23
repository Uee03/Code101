"""Exercise: may this caller delete a team? It needs the scope tasks:admin AND the role admin."""


def has_scope(claims, scope):
    return scope in claims["scope"].split()


def has_role(claims, role):
    return role in claims["realm_access"]["roles"]


def may_delete_team(claims):
    return has_scope(claims, "tasks:admin") and has_role(claims, "admin")


def status_for(claims):
    if claims is None:
        return 401
    return 204 if may_delete_team(claims) else 403


CALLERS = {
    "alice with tasks:admin": {"scope": "openid tasks:read tasks:write tasks:admin", "realm_access": {"roles": ["admin"]}},
    "alice without tasks:admin": {"scope": "openid tasks:read tasks:write", "realm_access": {"roles": ["admin"]}},
    "bob with tasks:admin": {"scope": "openid tasks:read tasks:write tasks:admin", "realm_access": {"roles": ["member"]}},
    "bob": {"scope": "openid tasks:read tasks:write", "realm_access": {"roles": ["member"]}},
}
for name, claims in CALLERS.items():
    print(f"{name}: {'allowed' if may_delete_team(claims) else 'refused'} ({status_for(claims)})")
print(f"no token: refused ({status_for(None)})")
