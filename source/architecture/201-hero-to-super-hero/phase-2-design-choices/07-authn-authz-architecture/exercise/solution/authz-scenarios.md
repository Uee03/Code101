# Authorisation scenarios

| Scenario | Expected status | Which check decides it |
|---|---|---|
| A request has no Authorization header | 401 | Check 1, the token is missing |
| Bob (a member, not an admin) holds the scope tasks:admin and calls DELETE on a team | 403 | Check 3, the role admin is missing; the scope alone is not enough |
| Bob is not a member of the Mobile Team and asks for that team | 404 | Check 4, non-members get 404 so ids cannot be probed |
| A token expired several minutes ago | 401 | Check 1, the expiry has passed beyond the allowed clock skew |
| Alice (admin) deletes a comment written by Bob | 204 | Checks 1 to 3 pass; the role admin is allowed to delete any comment |
