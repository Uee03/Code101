package auth

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"example.com/tasksteams/internal/store"
)

// UserLookup is the one thing the development authenticator needs from the data layer.
type UserLookup interface {
	GetUser(ctx context.Context, id string) (store.User, error)
}

// Dev is a stand-in for Keycloak until chapter 05. It trusts three request headers:
//
//	X-Dev-User    the id of a user in the users table
//	X-Dev-Roles   comma separated realm roles (default: member)
//	X-Dev-Scopes  comma separated scopes (default: all three)
//
// Anyone can send those headers, so this type must never run anywhere but on your own machine.
// Chapter 05 deletes it.
type Dev struct {
	Users UserLookup
}

func (d Dev) Authenticate(r *http.Request) (*Principal, error) {
	id := r.Header.Get("X-Dev-User")
	if id == "" {
		return nil, nil
	}
	user, err := d.Users.GetUser(r.Context(), id)
	if err != nil {
		return nil, errors.New("X-Dev-User is not a known user")
	}
	return &Principal{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Roles:       headerList(r, "X-Dev-Roles", RoleMember),
		Scopes:      headerList(r, "X-Dev-Scopes", ScopeRead, ScopeWrite, ScopeAdmin),
	}, nil
}

// headerList splits a comma separated header, or returns the defaults when the header is absent.
func headerList(r *http.Request, name string, defaults ...string) []string {
	raw := r.Header.Get(name)
	if raw == "" {
		return defaults
	}
	items := strings.Split(raw, ",")
	for i := range items {
		items[i] = strings.TrimSpace(items[i])
	}
	return items
}
