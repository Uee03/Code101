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
