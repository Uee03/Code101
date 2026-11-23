package httpapi

import (
	"net/http"
	"strconv"
	"strings"

	"example.com/tasksteams/internal/problem"
)

// etagOf makes the strong ETag of a resource: its version in quotes, for example "3".
func etagOf(version int) string { return `"` + strconv.Itoa(version) + `"` }

func parseETag(raw string) (int, bool) {
	if len(raw) < 3 || raw[0] != '"' || raw[len(raw)-1] != '"' {
		return 0, false
	}
	version, err := strconv.Atoi(raw[1 : len(raw)-1])
	return version, err == nil && version >= 1
}

// ifMatch reads the If-Match header. It returns the version the client last saw, or 0 for "any version"
// (the header is absent and optional, or it is *). A required header that is missing is the 428 problem.
func ifMatch(r *http.Request, required bool) (int, *problem.Problem) {
	raw := strings.TrimSpace(r.Header.Get("If-Match"))
	switch {
	case raw == "" && required:
		return 0, problem.PreconditionRequired("Send If-Match with the ETag you last read.")
	case raw == "" || raw == "*":
		return 0, nil
	}
	version, ok := parseETag(raw)
	if !ok {
		return 0, problem.BadRequest(`If-Match must be a quoted version such as "3".`)
	}
	return version, nil
}

// etagMatches implements the weak comparison of If-None-Match: a list of ETags, or *.
func etagMatches(header, etag string) bool {
	for _, candidate := range strings.Split(header, ",") {
		candidate = strings.TrimPrefix(strings.TrimSpace(candidate), "W/")
		if candidate == "*" || candidate == etag {
			return true
		}
	}
	return false
}

// respondEntity sends one resource with its ETag. A GET whose If-None-Match already names this version gets 304 and no body.
func respondEntity(w http.ResponseWriter, r *http.Request, status, version int, body any) {
	etag := etagOf(version)
	w.Header().Set("ETag", etag)
	if r.Method == http.MethodGet && etagMatches(r.Header.Get("If-None-Match"), etag) {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	writeJSON(w, r, status, body)
}
