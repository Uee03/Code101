"""Compute the PKCE code_challenge (method S256) from a code_verifier."""
import base64
import hashlib

verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
digest = hashlib.sha256(verifier.encode("ascii")).digest()
challenge = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
print("code_verifier :", verifier)
print("code_challenge:", challenge)
