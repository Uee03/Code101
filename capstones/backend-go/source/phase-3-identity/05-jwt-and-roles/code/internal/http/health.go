package httpapi

import (
	"context"
	"net/http"
	"time"
)

type healthDTO struct {
	Status   string `json:"status"`
	Version  string `json:"version"`
	Database string `json:"database,omitempty"`
}

// health answers without a token. It pings the database with a short deadline: 200 when it answers, 503 when not.
func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	if err := s.store.Ping(ctx); err != nil {
		s.logger.Warn("health: database is down", "error", err)
		writeJSON(w, r, http.StatusServiceUnavailable, healthDTO{Status: "degraded", Version: apiVersion, Database: "down"})
		return
	}
	writeJSON(w, r, http.StatusOK, healthDTO{Status: "ok", Version: apiVersion, Database: "up"})
}
