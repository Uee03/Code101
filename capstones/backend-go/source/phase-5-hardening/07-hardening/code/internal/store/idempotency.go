package store

import "context"

// IdempotencyRecord is what the database remembers about an Idempotency-Key.
type IdempotencyRecord struct {
	RequestHash string
	StatusCode  *int   // nil while the first request is still running
	Response    []byte // the stored response envelope, nil while the first request is still running
}

// ClaimKey tries to become the one request that owns (user, key). claimed is true for the owner. Any other request
// gets the existing record back and must replay it, reject it or ask the client to wait.
func (s *Store) ClaimKey(ctx context.Context, userID, key, requestHash string) (claimed bool, existing IdempotencyRecord, err error) {
	for range 3 { // the owner may release the key between our INSERT and our SELECT, so look again
		// A key older than 24 hours no longer counts; remove it so the INSERT below can succeed.
		if _, err := s.pool.Exec(ctx, "DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2 AND expires_at <= now()", userID, key); err != nil {
			return false, existing, mapError(err)
		}
		tag, err := s.pool.Exec(ctx, `INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES ($1, $2, $3)
			ON CONFLICT (user_id, key) DO NOTHING`, userID, key, requestHash)
		if err != nil {
			return false, existing, mapError(err)
		}
		if tag.RowsAffected() == 1 {
			return true, existing, nil
		}
		existing, err = collectOne[IdempotencyRecord](ctx, s.pool,
			"SELECT request_hash, status_code, response_body FROM idempotency_keys WHERE user_id = $1 AND key = $2", userID, key)
		if err == nil {
			return false, existing, nil
		}
	}
	return false, existing, &Error{Kind: KindConflict, Message: "The Idempotency-Key is being released; retry in a moment."}
}

// FinishKey stores the response of the owner so later requests with the same key can replay it.
func (s *Store) FinishKey(ctx context.Context, userID, key string, status int, response []byte) error {
	_, err := s.pool.Exec(ctx, "UPDATE idempotency_keys SET status_code = $3, response_body = $4 WHERE user_id = $1 AND key = $2",
		userID, key, status, response)
	return mapError(err)
}

// ReleaseKey forgets a key whose request failed, so the client can fix the request and send it again.
func (s *Store) ReleaseKey(ctx context.Context, userID, key string) error {
	_, err := s.pool.Exec(ctx, "DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2", userID, key)
	return mapError(err)
}
