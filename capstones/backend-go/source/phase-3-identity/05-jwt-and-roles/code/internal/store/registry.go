package store

import "context"

// EnsureUser creates the users row of a signed-in caller the first time the caller is seen. The id is the Keycloak sub,
// so the row and the token always refer to the same person. A caller who already has a row is left unchanged.
func (s *Store) EnsureUser(ctx context.Context, id, username, email, displayName string) error {
	_, err := s.pool.Exec(ctx, `INSERT INTO users (id, username, email, display_name) VALUES ($1, $2, $3, $4)
		ON CONFLICT DO NOTHING`, id, username, email, displayName)
	return mapError(err)
}
