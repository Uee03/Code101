# Phase 3: Identity

Chapter 03 replaces the development stand-in of chapter 02 with real validation of the Keycloak access token: RS256 only, signature from a cached JWKS, exact issuer, audience (string or list) `tasks-api`, expiry and not-before with 30 seconds of tolerance. Scopes (what the client may do) and roles plus team membership (what the user may do) combine. You forge an admin token, see chapter 02 accept it and chapter 03 refuse it, and run 14 broken tokens through the verifier offline. An appendix maps the settings to Authentik.

| Chapter | Lesson text | Folder |
|---------|-------------|--------|
| 03 Identity: validating Keycloak tokens, scopes and roles | `tutorials/phase-3-identity/03-identity.md` | `03-identity/` |

## Prerequisites
- Chapter 02 (or this pack, which holds the whole project at the end of chapter 03).
- Python 3.12 or newer, Docker with Compose v2, free host ports 5432, 8180 and 8000.
- `scripts/forge_token.py` and `scripts/token_rules.py` need PyJWT and `cryptography` (installed from `requirements.txt`).

## Folder layout
```text
03-identity/
  code/                  the whole project at the end of chapter 03
  exercise/starter/      claims.py with TODOs
  exercise/solution/     claims.py finished
  verify.json            what scripts/verify_labs.py runs
```

## Run it
```text
cd 03-identity/code
copy .env.example .env              (macOS and Linux: cp .env.example .env)
docker compose up -d --wait
python -m venv .venv
.venv\Scripts\Activate.ps1          (macOS and Linux: source .venv/bin/activate)
python -m pip install -r requirements.txt
python scripts/token_rules.py       (offline, no Keycloak needed)
python -m uvicorn app.main:app --port 8000
python scripts/conformance.py       (second terminal)
docker compose down -v              (when you are done)
```

## Conformance state
17 passed, 1 failed (`me`: the `RateLimit-*` headers arrive in phase 5).
