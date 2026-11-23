"""Exercise: print the realm roles inside bob's access token."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "code" / "scripts"))
import conformance

token = conformance.token_for("bob")
claims = conformance.claims_of(token)
print("bob roles: " + ", ".join(claims["realm_access"]["roles"]))
