// Package auth identifies the caller of a request and describes what the caller may do.
package auth

import (
	"context"
	"net/http"
	"slices"
)

// Scopes of the contract: what the client application may do on behalf of the user.
const (
	ScopeRead  = "tasks:read"
	ScopeWrite = "tasks:write"
	ScopeAdmin = "tasks:admin"
)

// Realm roles of the contract: what the user may do.
const (
	RoleAdmin  = "admin"
	RoleMember = "member"
)

// Principal is the authenticated caller.
type Principal struct {
	ID          string // the Keycloak sub, equal to users.id
	Username    string
	Email       string
	DisplayName string
	Roles       []string
	Scopes      []string
}

func (p *Principal) HasRole(role string) bool   { return slices.Contains(p.Roles, role) }
func (p *Principal) HasScope(scope string) bool { return slices.Contains(p.Scopes, scope) }
func (p *Principal) IsAdmin() bool              { return p.HasRole(RoleAdmin) }

// Authenticator turns the credentials of a request into a Principal.
//
// It returns (nil, nil) when the request carries no credentials at all, and (nil, err) when it carries
// credentials that are not valid. The HTTP layer answers both with 401, with a different message.
type Authenticator interface {
	Authenticate(r *http.Request) (*Principal, error)
}

type principalKey struct{}
type failureKey struct{}

// NewContext stores the outcome of authentication in the request context.
func NewContext(ctx context.Context, p *Principal, failure error) context.Context {
	ctx = context.WithValue(ctx, principalKey{}, p)
	return context.WithValue(ctx, failureKey{}, failure)
}

// FromContext returns the caller, or nil when the request is anonymous or its credentials were rejected.
func FromContext(ctx context.Context) *Principal {
	p, _ := ctx.Value(principalKey{}).(*Principal)
	return p
}

// FailureFromContext returns why the credentials were rejected, or nil.
func FailureFromContext(ctx context.Context) error {
	err, _ := ctx.Value(failureKey{}).(error)
	return err
}
