package main

import (
	"bytes"
	"crypto/ed25519"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func decodeUser(body string, maxBytes int64) (CreateUser, error) {
	req := httptest.NewRequest(http.MethodPost, "/users", strings.NewReader(body))
	return DecodeStrict[CreateUser](httptest.NewRecorder(), req, maxBytes)
}

func TestDecodeStrictRejectsBadBodies(t *testing.T) {
	cases := []struct {
		name string
		body string
		max  int64
		want error
	}{
		{"unknown field", `{"name":"Ada","admin":true}`, 1024, nil},
		{"trailing data", `{"name":"Ada"} {"name":"Eve"}`, 1024, nil},
		{"too large", `{"name":"` + strings.Repeat("a", 100) + `"}`, 32, ErrBodyTooLarge},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := decodeUser(tc.body, tc.max)
			if err == nil {
				t.Fatal("expected an error")
			}
			if tc.want != nil && !errors.Is(err, tc.want) {
				t.Fatalf("err = %v, want %v", err, tc.want)
			}
		})
	}
}

func TestValidate(t *testing.T) {
	good := CreateUser{Name: "Ada", Email: "ada@example.com", Role: "member"}
	if p := good.Validate(); len(p) != 0 {
		t.Fatalf("valid user got problems: %v", p)
	}

	bad := []CreateUser{
		{Name: "", Email: "ada@example.com", Role: "member"},
		{Name: "Ada\x00", Email: "ada@example.com", Role: "member"},
		{Name: "Ada", Email: "Ada <ada@example.com>", Role: "member"},
		{Name: "Ada", Email: "ada@example.com", Role: "root"},
	}
	for _, u := range bad {
		if len(u.Validate()) != 1 {
			t.Errorf("%+v: want exactly one problem, got %v", u, u.Validate())
		}
	}
}

func TestVerifierRejectsWrongAudienceExpiredAndForged(t *testing.T) {
	priv := ed25519.NewKeyFromSeed(bytes.Repeat([]byte{7}, ed25519.SeedSize))
	other := ed25519.NewKeyFromSeed(bytes.Repeat([]byte{8}, ed25519.SeedSize))
	keys := KeySet{"k1": priv.Public().(ed25519.PublicKey)}
	now := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	clock := func() time.Time { return now }

	good, err := NewIssuer("k1", priv, clock).Issue("billing", "inventory", time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	if sub, err := NewVerifier(keys, "inventory", clock).Verify(good); err != nil || sub != "billing" {
		t.Fatalf("good token: subject = %q, err = %v", sub, err)
	}

	forged, _ := NewIssuer("k1", other, clock).Issue("billing", "inventory", time.Minute)
	checks := []struct {
		name     string
		verifier *Verifier
		token    string
		reason   string
	}{
		{"wrong audience", NewVerifier(keys, "payments", clock), good, "wrong audience"},
		{"expired", NewVerifier(keys, "inventory", func() time.Time { return now.Add(time.Hour) }), good, "expired"},
		{"forged", NewVerifier(keys, "inventory", clock), forged, "bad signature"},
		{"unknown kid", NewVerifier(KeySet{}, "inventory", clock), good, "unverifiable"},
	}
	for _, c := range checks {
		_, err := c.verifier.Verify(c.token)
		if got := Reason(err); got != c.reason {
			t.Errorf("%s: reason = %q (err: %v), want %q", c.name, got, err, c.reason)
		}
	}
}

func TestIssueRejectsLongLivedTokens(t *testing.T) {
	priv := ed25519.NewKeyFromSeed(bytes.Repeat([]byte{7}, ed25519.SeedSize))
	_, err := NewIssuer("k1", priv, time.Now).Issue("billing", "inventory", 24*time.Hour)
	if err == nil {
		t.Fatal("a 24 hour service token must be refused")
	}
}

func TestMutualTLS(t *testing.T) {
	with, without, err := mtlsDemo()
	if err != nil {
		t.Fatal(err)
	}
	if with != "200 hello billing-service" || without != "rejected" {
		t.Fatalf("with = %q, without = %q", with, without)
	}
}

func TestReadSecretFromFileAndRedaction(t *testing.T) {
	path := filepath.Join(t.TempDir(), "db_password")
	if err := os.WriteFile(path, []byte("s3cr3t\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("DB_PASSWORD_FILE", path)

	s, err := ReadSecret("DB_PASSWORD")
	if err != nil {
		t.Fatal(err)
	}
	if s.Reveal() != "s3cr3t" || s.String() != "[redacted]" {
		t.Fatalf("Reveal = %q, String = %q", s.Reveal(), s.String())
	}
}

func TestReadSecretMissing(t *testing.T) {
	t.Setenv("L08_MISSING", "")
	if _, err := ReadSecret("L08_MISSING"); err == nil || !strings.Contains(err.Error(), "not set") {
		t.Fatalf("err = %v, want a 'not set' error", err)
	}
}
