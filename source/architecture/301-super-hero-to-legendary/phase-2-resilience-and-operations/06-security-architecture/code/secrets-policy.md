# Secrets policy

A secret is anything that proves identity or unlocks data: passwords, tokens, signing keys, database credentials.

Rules:
- No real secret is committed to Git. The repository holds example files with fake values, and the real file is ignored by Git.
- Each environment has its own secrets. A secret from one environment is never reused in another.
- Production secrets come from a secret store at start-up, not from files baked into an image.
- Each service has its own identity and the smallest rights that work, for example a database role that cannot change the schema.
- Secrets never appear in logs, traces, error messages, events or diagrams.
- Every secret has an owner and a way to rotate it without an outage.
- Secret scanning runs on every push, and a leaked secret is treated as compromised and rotated at once.

| Secret | Owner | Where kept | Rotation trigger |
|---|---|---|---|
| Database password for the application role | Platform maintainers | Secret store | Staff change, suspected leak, or a regular schedule the team sets |
| Keycloak administrator credential | Identity owner | Secret store | Staff change or suspected leak |
| Client secrets of confidential clients | Identity owner | Secret store | Staff change or suspected leak |
| Public signing keys | Keycloak | Published by Keycloak | Rotated by Keycloak; the API refetches on an unknown key id |
