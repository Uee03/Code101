---
track: capstone
level: 201
phase: 3
phase_name: identity
lesson: 05
title: "Identity: validating Keycloak tokens, roles and scopes"
time: 120 min
prerequisites: [capstone-backend-go-04, capstone-platform-03]
versions: { go: "1.27.4", jwt: "github.com/golang-jwt/jwt/v5 v5.3.1", keycloak_image: "quay.io/keycloak/keycloak:26.8.2" }
verified: 2026-11-23 on Windows 11, Go 1.27.4, Docker 29.9.3, Compose 5.7.0, curl 8.22.0, Python 3.15.2
source: capstones/backend-go/source/phase-3-identity/05-jwt-and-roles/
assets: []
---

# 05. Identity: validating Keycloak tokens, roles and scopes

## Why it matters
A concert ticket is useful because the door staff can check it without phoning the box office: the hologram, the date, the venue name and the seat are printed on it. An access token is the same: the API checks it **locally** (signature, issuer, audience, expiry) and never asks Keycloak per request. If the checks are wrong in one place, anyone with a printer gets in. This chapter writes those checks and removes the development stand-in.

## What you will build
- A `JWKS` cache that downloads Keycloak's public signing keys once and refreshes them when an unknown key id appears, without letting an attacker trigger endless downloads.
- A `JWT` authenticator that accepts only `RS256` tokens from the configured issuer for the audience `tasks-api`, with 30 seconds of clock skew, and builds the `Principal` (roles from `realm_access`, scopes from `scope`).
- First-use creation of the `users` row from the token.
- Removal of `internal/auth/dev.go`.

Conformance after this chapter (real run, Keycloak and Postgres from the platform, the API on the host): **17 passed, 1 failed**. Only `me` fails, on the missing `RateLimit-*` headers that chapter 07 adds.

## Before you start
- Chapter 04 done, or unzip `backend-go-phase-3-identity.zip` and open `05-jwt-and-roles/code`.
- Docker running; ports 5432 and 8180 free. Python 3.10+ for the token helper in the commands below and for the conformance script.
- The platform realm (`keycloak/realm-tasksteams.json`, explained in the platform chapter 03) defines the client `tasks-api` (the audience), the roles `admin` and `member`, the scopes `tasks:read`, `tasks:write`, `tasks:admin` and the users alice, bob and carol with the same ids as the seed. The issuer is `http://localhost:8180/realms/tasksteams`.

## Steps
### Step 1. Look at a token before you validate one
Start the stack (the API is not needed yet) and ask Keycloak for a token as alice. The `tasks-smoke` client allows the password grant for the fake users; real applications use the authorization code flow with PKCE (platform chapter 03).
```bash
cp .env.example .env
docker compose -p tasksteams up -d --wait db keycloak
```
(PowerShell: `Copy-Item .env.example .env`.) Expected (the first start of Keycloak takes up to a minute):
```text
 Container tasksteams-keycloak-1 Started
 Container tasksteams-db-1 Started
 Container tasksteams-db-1 Waiting
 Container tasksteams-keycloak-1 Waiting
 Container tasksteams-db-1 Healthy
 Container tasksteams-keycloak-1 Healthy
```

Get a token into a shell variable. The Python snippet only extracts the `access_token` field from Keycloak's JSON answer.

PowerShell:
```powershell
$alice = curl.exe -s -d "grant_type=password" -d "client_id=tasks-smoke" -d "username=alice" -d "password=alice-local-fake" --data-urlencode "scope=openid tasks:read tasks:write tasks:admin" http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/token | python -c "import json,sys; print(json.load(sys.stdin)['access_token'])"
```
bash (same command, assigned without `$`):
```bash
alice=$(curl -s -d "grant_type=password" -d "client_id=tasks-smoke" -d "username=alice" -d "password=alice-local-fake" --data-urlencode "scope=openid tasks:read tasks:write tasks:admin" http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/token | python -c "import json,sys; print(json.load(sys.stdin)['access_token'])")
```
The same command with `username=bob` and `password=bob-local-fake` fills `$bob` (`bob=...` in bash).

A JWT has three base64url parts separated by dots: header, payload, signature. The payload is **readable by anyone**; only the signature stops forgery. The claims the API uses:
```text
{
  "iss": "http://localhost:8180/realms/tasksteams",
  "aud": "tasks-api",
  "sub": "a11ce000-0000-4000-8000-000000000001",
  "scope": "openid tasks:write tasks:read tasks:admin email profile",
  "realm_access": {
    "roles": [
      "admin"
    ]
  },
  "preferred_username": "alice"
}
```
`iss` is the issuer, `aud` the audience (here a string, in other tokens a list), `sub` the user id (equal to `users.id`), `scope` the space separated scopes, `realm_access.roles` the realm roles.

### Step 2. The dependency
```bash
go get github.com/golang-jwt/jwt/v5@v5.3.1
go mod tidy
```
`golang-jwt/jwt` v5 parses and validates JWTs; it does the cryptography and the registered-claim checks, and you give it a **policy** (the options) and a **key function**. The JWKS code is your own, about 100 lines, because a JWKS cache is where the subtle bugs live and it is worth seeing once.
**File: `go.mod`**
```text
module example.com/tasksteams

go 1.27.4

require (
	github.com/golang-jwt/jwt/v5 v5.3.1
	github.com/jackc/pgx/v5 v5.13.0
)

require (
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.3 // indirect
	golang.org/x/sync v0.22.0 // indirect
	golang.org/x/text v0.41.0 // indirect
)
```

### Step 3. The key cache
Keycloak publishes its public keys at `/realms/tasksteams/protocol/openid-connect/certs` as a JSON Web Key Set (RFC 7517). Every token header names the key that signed it (`kid`).

**File: `internal/auth/jwks.go`**
```go
package auth

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"sync"
	"time"
)

// minRefresh limits how often an unknown key id may trigger a download, so a client that sends tokens with
// made-up key ids cannot turn the API into a request generator against Keycloak.
const minRefresh = 10 * time.Second

var errUnknownKey = errors.New("no signing key with this key id")

// JWKS caches the public signing keys of the identity provider (a JSON Web Key Set, RFC 7517).
type JWKS struct {
	url    string
	client *http.Client

	mu   sync.RWMutex
	keys map[string]*rsa.PublicKey

	refreshMu sync.Mutex // one download at a time; guards fetchedAt
	fetchedAt time.Time
}

func NewJWKS(url string) *JWKS {
	return &JWKS{url: url, client: &http.Client{Timeout: 5 * time.Second}, keys: map[string]*rsa.PublicKey{}}
}

// Key returns the public key for a key id. Known keys come from memory; an unknown id triggers one download.
func (j *JWKS) Key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	if key, ok := j.cached(kid); ok {
		return key, nil
	}
	j.refreshMu.Lock()
	defer j.refreshMu.Unlock()
	if key, ok := j.cached(kid); ok { // another request downloaded the set while we waited for the lock
		return key, nil
	}
	if !j.fetchedAt.IsZero() && time.Since(j.fetchedAt) < minRefresh {
		return nil, errUnknownKey
	}
	j.fetchedAt = time.Now()
	keys, err := j.download(ctx)
	if err != nil {
		return nil, err
	}
	j.mu.Lock()
	j.keys = keys
	j.mu.Unlock()
	if key, ok := keys[kid]; ok {
		return key, nil
	}
	return nil, errUnknownKey
}

func (j *JWKS) cached(kid string) (*rsa.PublicKey, bool) {
	j.mu.RLock()
	defer j.mu.RUnlock()
	key, ok := j.keys[kid]
	return key, ok
}

type jsonWebKey struct {
	Kty string `json:"kty"`
	Kid string `json:"kid"`
	Use string `json:"use"`
	N   string `json:"n"`
	E   string `json:"e"`
}

func (j *JWKS) download(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, j.url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := j.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("download signing keys: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("download signing keys: HTTP %d", resp.StatusCode)
	}
	var set struct {
		Keys []jsonWebKey `json:"keys"`
	}
	if err := json.NewDecoder(io.LimitReader(resp.Body, 1<<20)).Decode(&set); err != nil {
		return nil, fmt.Errorf("read signing keys: %w", err)
	}
	keys := map[string]*rsa.PublicKey{}
	for _, k := range set.Keys {
		if k.Kty != "RSA" || (k.Use != "" && k.Use != "sig") { // Keycloak also lists an encryption key
			continue
		}
		key, err := k.publicKey()
		if err != nil {
			return nil, fmt.Errorf("signing key %q: %w", k.Kid, err)
		}
		keys[k.Kid] = key
	}
	return keys, nil
}

// publicKey rebuilds an RSA public key from its modulus (n) and exponent (e), both base64url without padding.
func (k jsonWebKey) publicKey() (*rsa.PublicKey, error) {
	n, err := base64.RawURLEncoding.DecodeString(k.N)
	if err != nil {
		return nil, err
	}
	e, err := base64.RawURLEncoding.DecodeString(k.E)
	if err != nil {
		return nil, err
	}
	return &rsa.PublicKey{N: new(big.Int).SetBytes(n), E: int(new(big.Int).SetBytes(e).Int64())}, nil
}
```
- **Fast path:** a key that is already in memory is returned under a read lock; no network.
- **Slow path:** an unknown `kid` takes the refresh lock, checks the cache again (another request may have just loaded it) and only then downloads. Only one download runs at a time, and readers of known keys never wait for it, because the download happens under `refreshMu`, not under `mu`.
- **Throttle:** an unknown `kid` may trigger a download at most once every 10 seconds (`minRefresh`). Without it, anyone could send tokens with made-up key ids and turn the API into a generator of requests against Keycloak. The price: after Keycloak rotates its keys, a token signed with the new key waits at most 10 seconds for a refresh.
- `download` has a 5-second timeout, reads at most 1 MiB and keeps only RSA signing keys (Keycloak also lists an encryption key). `publicKey` rebuilds an `rsa.PublicKey` from the modulus `n` and exponent `e`.

### Step 4. The validator
**File: `internal/auth/jwt.go`**
```go
package auth

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// UserRegistry creates the users row of a caller the first time the caller is seen.
type UserRegistry interface {
	EnsureUser(ctx context.Context, id, username, email, displayName string) error
}

// JWT validates Keycloak access tokens (RFC 9068 JWT access tokens) and builds the Principal from their claims.
type JWT struct {
	parser *jwt.Parser
	keys   *JWKS
	users  UserRegistry
	known  sync.Map // subjects whose users row exists, so most requests skip the database
}

// NewJWT builds a validator for one issuer and one audience.
//
// The parser options are the whole validation policy:
//   - only RS256, so "alg": "none" and an HMAC token signed with the public key are refused;
//   - iss must equal the configured issuer exactly;
//   - aud (a string or a list in the token) must contain our audience;
//   - exp must be present and in the future, nbf is checked when present, both with 30 seconds of clock skew.
func NewJWT(issuer, audience string, keys *JWKS, users UserRegistry) *JWT {
	return &JWT{
		keys:  keys,
		users: users,
		parser: jwt.NewParser(
			jwt.WithValidMethods([]string{"RS256"}),
			jwt.WithIssuer(issuer),
			jwt.WithAudience(audience),
			jwt.WithExpirationRequired(),
			jwt.WithLeeway(30*time.Second),
		),
	}
}

// accessClaims are the claims of a Keycloak access token that the API uses besides the registered ones.
type accessClaims struct {
	jwt.RegisteredClaims
	Scope             string `json:"scope"`
	PreferredUsername string `json:"preferred_username"`
	Email             string `json:"email"`
	Name              string `json:"name"`
	RealmAccess       struct {
		Roles []string `json:"roles"`
	} `json:"realm_access"`
}

// Authenticate implements Authenticator: (nil, nil) without a header, an error for a token that is not valid.
func (v *JWT) Authenticate(r *http.Request) (*Principal, error) {
	header := r.Header.Get("Authorization")
	if header == "" {
		return nil, nil
	}
	scheme, token, found := strings.Cut(header, " ")
	if !found || !strings.EqualFold(scheme, "Bearer") || strings.TrimSpace(token) == "" {
		return nil, errors.New("the Authorization header is not a Bearer token")
	}
	var claims accessClaims
	if _, err := v.parser.ParseWithClaims(strings.TrimSpace(token), &claims, v.keyFunc(r.Context())); err != nil {
		return nil, fmt.Errorf("token rejected: %w", err)
	}
	if claims.Subject == "" {
		return nil, errors.New("token rejected: no sub claim")
	}
	p := &Principal{
		ID:          claims.Subject,
		Username:    firstNonEmpty(claims.PreferredUsername, claims.Subject),
		Email:       firstNonEmpty(claims.Email, claims.Subject+"@unknown.invalid"),
		DisplayName: firstNonEmpty(claims.Name, claims.PreferredUsername, claims.Subject),
		Roles:       claims.RealmAccess.Roles,
		Scopes:      strings.Fields(claims.Scope),
	}
	if err := v.ensureUser(r.Context(), p); err != nil {
		return nil, fmt.Errorf("register user: %w", err)
	}
	return p, nil
}

// keyFunc is called by the parser after it has read the header: it finds the public key for the token's kid.
func (v *JWT) keyFunc(ctx context.Context) jwt.Keyfunc {
	return func(token *jwt.Token) (any, error) {
		kid, _ := token.Header["kid"].(string)
		if kid == "" {
			return nil, errors.New("the token header has no kid")
		}
		return v.keys.Key(ctx, kid)
	}
}

func (v *JWT) ensureUser(ctx context.Context, p *Principal) error {
	if _, ok := v.known.Load(p.ID); ok {
		return nil
	}
	if err := v.users.EnsureUser(ctx, p.ID, p.Username, p.Email, p.DisplayName); err != nil {
		return err
	}
	v.known.Store(p.ID, struct{}{})
	return nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
```
The options of `jwt.NewParser` are the whole policy, and each blocks a real attack:

| Option | Blocks |
|--------|--------|
| `WithValidMethods(["RS256"])` | `"alg":"none"` tokens, and an `HS256` token signed with the public key as the secret ("algorithm confusion") |
| `WithIssuer(issuer)` | tokens from another realm or another identity provider |
| `WithAudience(audience)` | tokens made for another API; the library accepts `aud` as a string or a list (`ClaimStrings`) |
| `WithExpirationRequired()` | tokens without an `exp`, which would live forever |
| `WithLeeway(30s)` | false rejections caused by small clock differences |

The signature is verified with the key that `keyFunc` returns for the token's `kid`. After `ParseWithClaims` succeeds the claims are trustworthy; before it they are not (the exercise below reads a payload *without* trusting it, to show the difference). `Authenticate` returns `(nil, nil)` when there is no `Authorization` header and an error for anything wrong, which the HTTP layer from chapter 02 already turns into `401` with `error="invalid_token"`. The error text (for example `token has invalid issuer`) goes to the log, never to the client.

`ensureUser` makes the "user row is created on the first authenticated request" rule of the contract true: the `sync.Map` remembers the subjects already registered, so most requests do not touch the database for it.

**File: `internal/store/registry.go`**
```go
package store

import "context"

// EnsureUser creates the users row of a signed-in caller the first time the caller is seen. The id is the Keycloak sub,
// so the row and the token always refer to the same person. A caller who already has a row is left unchanged.
func (s *Store) EnsureUser(ctx context.Context, id, username, email, displayName string) error {
	_, err := s.pool.Exec(ctx, `INSERT INTO users (id, username, email, display_name) VALUES ($1, $2, $3, $4)
		ON CONFLICT DO NOTHING`, id, username, email, displayName)
	return mapError(err)
}
```
`ON CONFLICT DO NOTHING` without a target ignores any unique violation (same id, or the same username or e-mail with another id). That keeps first-use creation from failing when the seed already holds the user.

### Step 5. Configuration and the program
**File: `internal/config/config.go`**
```go
// Package config reads the settings of the service from environment variables.
package config

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

// Config holds every setting the service needs. It is built once at start-up and never changed.
type Config struct {
	ListenAddr  string
	LogLevel    slog.Level
	LogFormat   string
	DatabaseURL string
	PublicURL   string
	Issuer      string // the iss claim a token must carry
	Audience    string // the aud value a token must contain
	JWKSURL     string // where the signing keys are downloaded; may differ from the issuer host inside Docker
}

// Load reads the environment and returns an error for a value it cannot use.
func Load() (Config, error) {
	cfg := Config{
		ListenAddr: env("LISTEN_ADDR", "127.0.0.1:8000"),
		LogFormat:  env("LOG_FORMAT", "text"),
		// The default is the disposable password of the platform stack. Real deployments set DATABASE_URL.
		DatabaseURL: env("DATABASE_URL", "postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams"),
		PublicURL:   strings.TrimRight(env("PUBLIC_URL", "http://localhost:8000"), "/"),
		Issuer:      env("KEYCLOAK_ISSUER", "http://localhost:8180/realms/tasksteams"),
		Audience:    env("KEYCLOAK_AUDIENCE", "tasks-api"),
		JWKSURL:     env("KEYCLOAK_JWKS_URL", "http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs"),
	}
	if err := cfg.LogLevel.UnmarshalText([]byte(env("LOG_LEVEL", "info"))); err != nil {
		return Config{}, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	if cfg.LogFormat != "text" && cfg.LogFormat != "json" {
		return Config{}, fmt.Errorf("LOG_FORMAT must be text or json, got %q", cfg.LogFormat)
	}
	return cfg, nil
}

// env returns the variable when it is set and not blank, otherwise the fallback.
func env(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && strings.TrimSpace(value) != "" {
		return value
	}
	return fallback
}
```
Three new settings: `KEYCLOAK_ISSUER` (what the token must say), `KEYCLOAK_AUDIENCE` and `KEYCLOAK_JWKS_URL` (where to fetch keys). The issuer and the key URL are separate settings on purpose: inside Docker the issuer in the token is `http://localhost:8180/...` (what browsers use) while the API reaches Keycloak at `http://keycloak:8080/...`. Chapter 06 sets that difference.

**File: `cmd/api/main.go`**
```go
// Command api is the Tasks and Teams backend written in Go.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/config"
	httpapi "example.com/tasksteams/internal/http"
	"example.com/tasksteams/internal/store"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "fatal:", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	logger := newLogger(cfg)
	slog.SetDefault(logger)

	// ctx is cancelled by Ctrl+C (os.Interrupt) or by `docker stop` (SIGTERM).
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := store.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer db.Close()

	verifier := auth.NewJWT(cfg.Issuer, cfg.Audience, auth.NewJWKS(cfg.JWKSURL), db)
	logger.Info("token validation", "issuer", cfg.Issuer, "audience", cfg.Audience, "jwks_url", cfg.JWKSURL)

	srv := &http.Server{
		Addr: cfg.ListenAddr,
		Handler: httpapi.NewServer(httpapi.Deps{
			Logger:    logger,
			Store:     db,
			Auth:      verifier,
			PublicURL: cfg.PublicURL,
		}).Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
		ErrorLog:          slog.NewLogLogger(logger.Handler(), slog.LevelWarn),
	}

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("listening", "addr", cfg.ListenAddr)
		serveErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serveErr:
		return err // ListenAndServe only returns before Shutdown when it failed, for example "address already in use"
	case <-ctx.Done():
		logger.Info("shutting down", "reason", "signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("graceful shutdown: %w", err)
	}
	logger.Info("stopped")
	return nil
}

func newLogger(cfg config.Config) *slog.Logger {
	opts := &slog.HandlerOptions{Level: cfg.LogLevel}
	if cfg.LogFormat == "json" {
		return slog.New(slog.NewJSONHandler(os.Stdout, opts))
	}
	return slog.New(slog.NewTextHandler(os.Stdout, opts))
}
```
`auth.NewJWT(...)` replaces `auth.Dev{...}`. Because both implement `auth.Authenticator`, nothing in `internal/http` changed.

### Step 6. Delete the stand-in
```bash
rm internal/auth/dev.go
```
(PowerShell: `Remove-Item internal/auth/dev.go`.) The development stand-in is gone; leaving a header that can claim any identity next to real authentication is a classic way to ship a backdoor.

### Step 7. Check and run
```bash
gofmt -l .
go vet ./...
go run ./cmd/api
```

#### The `.gitignore` of this chapter (unchanged from chapter 01)
Your `.env` now also holds the Keycloak settings, so it must stay out of Git. The same `.gitignore` as in chapter 01, shown again so you can check your copy.

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
*.exe
.env
```

- `bin/`: compiled programs; rebuilt on every machine.
- `*.exe`: Windows programs that `go build` writes next to the source.
- `.env`: your local settings. Never commit it; `.env.example` is the committed template.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
With `$alice` and `$bob` set as in step 1.

0. The API is up and reaches the database (no token needed):
```bash
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:8000/health
```
```text
{"status":"ok","version":"1.0.0","database":"up"}
HTTP 200
```

1. Call the API with the token:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "Authorization: Bearer $alice" http://127.0.0.1:8000/v1/me
curl -s -w "\nHTTP %{http_code}\n" -H "Authorization: Bearer $bob" http://127.0.0.1:8000/v1/me
```
```text
{"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["openid","tasks:write","tasks:read","tasks:admin","email","profile"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"lead"}]}
HTTP 200
```
```text
{"id":"b0b00000-0000-4000-8000-000000000002","username":"bob","email":"bob@tasksteams.test","displayName":"Bob Member","roles":["member"],"scopes":["openid","tasks:write","tasks:read","tasks:admin","email","profile"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","role":"member"},{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"member"}]}
HTTP 200
```
The `roles` come from the token (`admin` for alice, `member` for bob), the `teams` from the database. The `scopes` list is what the client may do; `openid`, `profile` and `email` are OpenID Connect scopes and harmless.

2. No token, a garbage token, a token with its signature damaged, an unsigned (`alg: none`) token and the wrong authentication scheme. All are `401`; only the log tells them apart:
```bash
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:8000/v1/me
curl -s -i -H "Authorization: Bearer abc.def.ghi" http://127.0.0.1:8000/v1/me
curl -s -w "\nHTTP %{http_code}\n" -H "Authorization: Basic YWxpY2U6YWxpY2U=" http://127.0.0.1:8000/v1/me
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"5bf2b153ac04bd7725bbbac37b2f3b88"}
HTTP 401
```
```text
HTTP/1.1 401 Unauthorized
Content-Type: application/problem+json
Www-Authenticate: Bearer realm="tasksteams", error="invalid_token"
X-Trace-Id: e31515393466fc2f4ebe993634e07200
Date: Mon, 23 Nov 2026 08:41:32 GMT
Content-Length: 208

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"e31515393466fc2f4ebe993634e07200"}
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"5687fa20dba3874661d194f43401078d"}
HTTP 401
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"eb5b4c03b2b75de81fb48ee3304552da"}
HTTP 401
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"2ce24d6ee642053dd763cf06255db3a0"}
HTTP 401
```
(To damage a signature, change the last characters of `$alice` and send it; for `alg: none`, send `eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhMTFjZTAwMC0wMDAwLTQwMDAtODAwMC0wMDAwMDAwMDAwMDEiLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgxODAvcmVhbG1zL3Rhc2tzdGVhbXMifQ.`.) The server log has one warning per refusal, with the reason and the trace id, but **never the token**:
```text
level=WARN msg="authentication failed" reason="token rejected: token is malformed: could not JSON decode header: invalid character 'i' looking for beginning of value" trace_id=e31515393466fc2f4ebe993634e07200
level=WARN msg="authentication failed" reason="token rejected: token signature is invalid: crypto/rsa: verification error" trace_id=5687fa20dba3874661d194f43401078d
level=WARN msg="authentication failed" reason="token rejected: token signature is invalid: signing method none is invalid" trace_id=eb5b4c03b2b75de81fb48ee3304552da
level=WARN msg="authentication failed" reason="the Authorization header is not a Bearer token" trace_id=2ce24d6ee642053dd763cf06255db3a0
```
The `Www-Authenticate` header of the garbage-token answer is the RFC 6750 challenge: `Bearer realm="tasksteams", error="invalid_token"`. A request with no token at all gets the same header without the `error`.

3. Roles decide what a person may do:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "Authorization: Bearer $bob" "http://127.0.0.1:8000/v1/audit-log?limit=1"
curl -s -w "\nHTTP %{http_code}\n" -H "Authorization: Bearer $alice" "http://127.0.0.1:8000/v1/audit-log?limit=1"
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "Authorization: Bearer $bob" -H "Content-Type: application/json" --data-binary @requests/team-valid.json http://127.0.0.1:8000/v1/teams
```
```text
{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"The admin role is required.","instance":"/v1/audit-log","traceId":"f7c0b40f769e03f5d21c66a10736caa5"}
HTTP 403
```
```text
{"items":[{"id":21,"occurredAt":"2026-11-23T08:41:06.919278Z","actorId":"a11ce000-0000-4000-8000-000000000001","action":"create","entityType":"comment","entityId":"c0000000-0000-4000-8000-000000000003","details":{"id":"c0000000-0000-4000-8000-000000000003","body":"The emulator needs adb reverse for port 8180.","task_id":"7a500000-0000-4000-8000-000000000007","author_id":"b0b00000-0000-4000-8000-000000000002","created_at":"2026-11-23T08:41:06.919278+00:00"}}],"page":{"limit":1,"nextCursor":"eyJzIjoiYXVkaXQiLCJ0IjoiMjAyNi0xMS0yM1QwODo0MTowNi45MTkyNzhaIiwiaSI6IjIxIn0"}}
HTTP 200
```
```text
{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"The admin role is required.","instance":"/v1/teams","traceId":"bfe6a6912be97453a0a5b4e3875cfaa6"}
HTTP 403
```
Bob's token holds the scope `tasks:admin`, yet he is refused: **the effective permission is the intersection of scope and role**. A scope alone never makes anyone an admin. The scope check itself is the `handle` function of chapter 02 (`tasks:read` for reads, `tasks:write` for changes, `tasks:admin` for the audit trail and team deletion); the `tasks-smoke` client holds all three scopes, so its tokens cannot show a scope refusal. Web and mobile clients request `tasks:admin` only on demand, and their tokens will.

4. Run the conformance script (from the project folder, with the API on port 8000):
```bash
python scripts/conformance.py
```
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: header RateLimit-Limit missing or not a number
PASS  create team (201, Location and ETag set, team 186faba9-8553-4a61-ad61-37d5c0c2436e)
PASS  create project (201, project 81c70046-7c2f-498f-affd-2f5c6b507b7e)
PASS  create task with Idempotency-Key (created once, replay returned the same task, other body gave 422)
PASS  get task with ETag (ETag "1", If-None-Match gave 304)
PASS  update with If-Match (200, version 1 -> 2)
PASS  stale If-Match gives 412 (stale If-Match gave 412, missing If-Match gave 428)
PASS  cursor pagination (2 + 1 tasks, no overlap, last page has nextCursor null)
PASS  401 without token (401 problem details with a Bearer challenge)
PASS  403 for member on admin route (bob (member) gets 403 on the audit log and on creating a team)
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
PASS  audit log (task create and update are in the audit trail)
PASS  cleanup (team deleted, then 404)
17 passed, 1 failed
```
**17 of 18.** The only failure is `me`: the contract wants `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` on every response and the API does not send them yet (chapter 07).

Stop the server, then `docker compose -p tasksteams down -v --remove-orphans`.

## How it works
```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant A as API
    participant K as Keycloak
    C->>A: GET /v1/me with Authorization Bearer token
    A->>A: read the header: "Bearer", then the token
    A->>A: parse header, kid, alg must be RS256
    A->>K: GET certs, only for an unknown kid, at most every 10 s
    K-->>A: signing keys
    A->>A: verify the signature, iss, aud, exp, nbf with 30 s skew
    A->>A: roles from realm_access.roles, scopes from scope
    A->>A: ensure the users row exists
    A->>A: handle: scope check (403), then the handler: role and team checks (403, 404)
    A-->>C: 200 or a problem
```
- **Authentication versus authorization.** `Authenticate` answers "who is this and is the token real" (401). `handle` and `authorize` answer "may they do this" (403, or 404 to hide existence).
- **Local validation versus introspection.** The API never calls Keycloak per request. A revoked token stays valid until it expires (5 minutes in this realm); the short lifetime is the compensation. When instant revocation matters, add token introspection (a network call per request, or per few seconds with a cache) for the sensitive routes only.
- **Failure modes.** Keycloak down: tokens signed with an already cached key keep working; a new key id cannot be fetched and those requests get 401 (the log names the download error). Clock skew beyond 30 seconds: valid tokens look expired or "not yet valid". Key rotation: the first request with the new `kid` triggers a refresh; the throttle bounds the cost.
- **What the API does not trust.** The `Authorization` header is the only credential. There is no cookie, so there is no CSRF problem for this API; if a future client used cookies this changes.

New terms: **JWT**, **JWKS**, **issuer**, **audience**, **claim**, **bearer token**, **algorithm confusion**, **clock skew**, **introspection**, **scope** versus **role**. See the [glossary](../../GLOSSARY.md).

## Try it
**Exercise.** Write `payloadOf`: decode the middle part of a token with `base64.RawURLEncoding` and unmarshal it, **without checking the signature**. It is how you read claims while debugging, and the last line of the program is the lesson: never authorize from such a payload.

**File: `exercise/starter/main.go`**
```go
package main

import (
	"fmt"
	"strings"
)

// A toy token for practice: header, payload and a fake signature. Nothing here is a real credential.
const token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImRlbW8ifQ.eyJzdWIiOiJib2IiLCJhdWQiOlsidGFza3MtYXBpIiwiYWNjb3VudCJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsibWVtYmVyIl19LCJzY29wZSI6Im9wZW5pZCB0YXNrczpyZWFkIn0.c2lnbmF0dXJl"

type claims struct {
	Subject     string   `json:"sub"`
	Audience    []string `json:"aud"`
	Scope       string   `json:"scope"`
	RealmAccess struct {
		Roles []string `json:"roles"`
	} `json:"realm_access"`
}

// payloadOf reads the claims of a token WITHOUT checking its signature, only to look inside it.
// TODO: split the token at the dots, decode the middle part with base64.RawURLEncoding and unmarshal the JSON.
func payloadOf(token string) (claims, error) {
	return claims{}, fmt.Errorf("not implemented")
}

func main() {
	c, err := payloadOf(token)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	fmt.Println("sub:   ", c.Subject)
	fmt.Println("aud:   ", c.Audience)
	fmt.Println("roles: ", c.RealmAccess.Roles)
	fmt.Println("scopes:", strings.Fields(c.Scope))
	fmt.Println("this payload was read, not verified: never authorize anyone from it")
}
```

<details><summary>Solution</summary>

**File: `exercise/solution/main.go`**
```go
package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

// A toy token for practice: header, payload and a fake signature. Nothing here is a real credential.
const token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImRlbW8ifQ.eyJzdWIiOiJib2IiLCJhdWQiOlsidGFza3MtYXBpIiwiYWNjb3VudCJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsibWVtYmVyIl19LCJzY29wZSI6Im9wZW5pZCB0YXNrczpyZWFkIn0.c2lnbmF0dXJl"

type claims struct {
	Subject     string   `json:"sub"`
	Audience    []string `json:"aud"`
	Scope       string   `json:"scope"`
	RealmAccess struct {
		Roles []string `json:"roles"`
	} `json:"realm_access"`
}

// payloadOf reads the claims of a token WITHOUT checking its signature, only to look inside it.
func payloadOf(token string) (claims, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return claims{}, errors.New("a JWT has three parts separated by dots")
	}
	raw, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return claims{}, err
	}
	var c claims
	return c, json.Unmarshal(raw, &c)
}

func main() {
	c, err := payloadOf(token)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	fmt.Println("sub:   ", c.Subject)
	fmt.Println("aud:   ", c.Audience)
	fmt.Println("roles: ", c.RealmAccess.Roles)
	fmt.Println("scopes:", strings.Fields(c.Scope))
	fmt.Println("this payload was read, not verified: never authorize anyone from it")
}
```
Output:
```text
sub:    bob
aud:    [tasks-api account]
roles:  [member]
scopes: [openid tasks:read]
this payload was read, not verified: never authorize anyone from it
```
Note `aud` is a list here. The real validator accepts both shapes because `jwt.ClaimStrings` decodes a string or a list.
</details>

## Check yourself
1. Why does the parser list `RS256` explicitly?
   <details><summary>Answer</summary>Otherwise the token decides how it is checked. `alg: none` would mean "no signature", and a token signed with HMAC using the public key as the secret would pass a naive check. A fixed allow-list closes both.</details>
2. A client with the scope `tasks:admin` and the role `member` calls `GET /v1/audit-log`. Result?
   <details><summary>Answer</summary>403. The route needs the scope **and** `requireAdmin` needs the role.</details>
3. Why does the JWKS cache throttle refreshes?
   <details><summary>Answer</summary>An attacker can send tokens with random `kid` values. Each unknown value would cause a download from Keycloak. One refresh per 10 seconds bounds that.</details>
4. The API runs in Docker and fetches keys from `http://keycloak:8080`, but the tokens say `iss: http://localhost:8180/...`. Which setting must match the token?
   <details><summary>Answer</summary>`KEYCLOAK_ISSUER` must equal the token's `iss` exactly. `KEYCLOAK_JWKS_URL` only says where to download keys from.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or a `.exe` file as new files, or a password appears in a commit | `.gitignore` is missing, or it was created after the files were already tracked | Create the `.gitignore` shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin`), commit, and replace any real secret that was ever committed |
| `token rejected: token has invalid claims: token has invalid issuer` | `KEYCLOAK_ISSUER` differs from the token's `iss` (here: `http://keycloak:8080/realms/tasksteams` was configured) | Set it to exactly `http://localhost:8180/realms/tasksteams` |
| `token rejected: token has invalid claims: token has invalid audience` | `KEYCLOAK_AUDIENCE` is not in the token's `aud` (here: `another-api`) | Use `tasks-api`, the audience mapper of the realm |
| `token rejected: token is unverifiable: error while executing keyfunc: download signing keys: Get "http://127.0.0.1:18999/certs": dial tcp 127.0.0.1:18999: connectex: No connection could be made because the target machine actively refused it.` | `KEYCLOAK_JWKS_URL` is wrong or Keycloak is down | Check the URL in a browser; the realm answers at `/realms/tasksteams/protocol/openid-connect/certs` |
| `token rejected: token signature is invalid: signing method none is invalid` | An unsigned token | Expected for an attack; legitimate clients never send it |

The first three rows come from running the API three times with a deliberately wrong setting, then reading its log:
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"0d05a99b0ca4838b7c56bafab74e713a"}
HTTP 401
level=WARN msg="authentication failed" reason="token rejected: token has invalid claims: token has invalid issuer" trace_id=0d05a99b0ca4838b7c56bafab74e713a
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"38043b2131756ba9f4d7ad1185a2f0ff"}
HTTP 401
level=WARN msg="authentication failed" reason="token rejected: token has invalid claims: token has invalid audience" trace_id=38043b2131756ba9f4d7ad1185a2f0ff
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"270b144cad4507ca93ba218cff4901f3"}
HTTP 401
level=WARN msg="authentication failed" reason="token rejected: token is unverifiable: error while executing keyfunc: download signing keys: Get \"http://127.0.0.1:18999/certs\": dial tcp 127.0.0.1:18999: connectex: No connection could be made because the target machine actively refused it." trace_id=270b144cad4507ca93ba218cff4901f3
```

## Best practice
Validate access tokens locally with a fixed algorithm allow-list, an exact issuer, the audience of this API and an expiry, fetch keys from the issuer's JWKS with a throttled refresh, and treat roles and scopes as two separate checks. Source: RFC 8725 JSON Web Token Best Current Practices https://www.rfc-editor.org/info/rfc8725, RFC 9068 JWT Profile for OAuth 2.0 Access Tokens https://www.rfc-editor.org/info/rfc9068 and the golang-jwt documentation https://pkg.go.dev/github.com/golang-jwt/jwt/v5

## Next lesson
06. Run and ship: a multi-stage Dockerfile with a static binary and a non-root runtime image, a Compose override that joins the platform network and a container healthcheck.
