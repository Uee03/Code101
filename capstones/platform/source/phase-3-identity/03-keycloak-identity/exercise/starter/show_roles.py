"""Exercise: print the realm roles inside bob's access token."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "code" / "scripts"))
import conformance

# TODO 1: get bob's access token with conformance.token_for("bob")
# TODO 2: decode its claims with conformance.claims_of(token)
# TODO 3: print "bob roles: " followed by the roles from claims["realm_access"]["roles"], joined with ", "
