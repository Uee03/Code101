package httpapi

import "net/http"

type healthDTO struct {
	Status   string `json:"status"`
	Version  string `json:"version"`
	Database string `json:"database,omitempty"`
}

// health answers without a token. This first version only proves the process is up.
func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, r, http.StatusOK, healthDTO{Status: "ok", Version: apiVersion})
}
