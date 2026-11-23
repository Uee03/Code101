# Review of legacy-compose.yml

## Findings the audit reports (10)
- Line 3 and line 12: `latest` or no tag, so the image can change under you.
- Line 5 and line 14: ports published on every interface, including the database.
- Line 8 and line 16: secret values written in the file.
- Missing: user, read_only, cap_drop and no-new-privileges.

## Findings only a human finds
- The database URL on line 7 contains a password and the lint cannot see it: move it to a secret file.
- `depends_on` without a health condition: the web service can start before the database accepts connections.
- No healthcheck on either service: nothing knows when they are ready or broken.
- Data in a host folder `./pgdata`: ownership and backup depend on the host, and a wrong `docker compose down -v` habit is not the only way to lose it. Use a named volume and a scheduled backup stored elsewhere.
- No backup or restore drill is described: data loss cannot be recovered.
- No restart policy, memory limit or log rotation: one crash stays down; a leak or a log flood takes the host.
- The web service listens on port 80 on the host: use a reverse proxy with TLS in front, and publish to loopback.

## Decision
Do not launch. Several MUST items fail (secrets, published database port, no health checks, no backup). Launch after the fixed file passes the audit, a restore drill passes and the owner accepts any remaining risks with an expiry date.
