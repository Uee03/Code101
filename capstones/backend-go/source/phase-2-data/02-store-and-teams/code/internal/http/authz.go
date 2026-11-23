package httpapi

import (
	"net/http"
	"strings"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
)

// authenticate runs on every /v1 request. It never rejects: it records who the caller is, or why the credentials
// were refused, and leaves the 401 to the route (see handle), so that /health and unknown paths stay open.
func (s *Server) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/v1/") {
			next.ServeHTTP(w, r)
			return
		}
		principal, err := s.auth.Authenticate(r)
		if err != nil {
			s.logger.Warn("authentication failed", "reason", err.Error(), "trace_id", problem.TraceID(r.Context()))
		}
		if principal != nil {
			infoFrom(r.Context()).userID = principal.ID
		}
		next.ServeHTTP(w, r.WithContext(auth.NewContext(r.Context(), principal, err)))
	})
}

// handle registers a route that needs a signed-in caller whose token carries the given scope.
func (s *Server) handle(mux *http.ServeMux, pattern, scope string, h http.HandlerFunc) {
	mux.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
		principal := auth.FromContext(r.Context())
		if principal == nil {
			p := problem.Unauthorized("A bearer access token is required.")
			if auth.FailureFromContext(r.Context()) != nil {
				p = problem.Unauthorized("The access token is invalid or expired.").
					WithHeader("WWW-Authenticate", `Bearer realm="tasksteams", error="invalid_token"`)
			}
			problem.Write(w, r, p)
			return
		}
		if !principal.HasScope(scope) {
			problem.Write(w, r, problem.Forbidden("The token needs the scope "+scope+"."))
			return
		}
		h(w, r)
	})
}

// requireAdmin answers 403 unless the caller has the admin realm role.
func requireAdmin(w http.ResponseWriter, r *http.Request) (*auth.Principal, bool) {
	principal := auth.FromContext(r.Context())
	if !principal.IsAdmin() {
		problem.Write(w, r, problem.Forbidden("The admin role is required."))
		return nil, false
	}
	return principal, true
}

type teamLevel int

const (
	levelMember teamLevel = iota // any member of the team
	levelLead                    // a lead of the team
)

// authorize decides whether the caller may act on a team's objects. what names the object for the message.
//
// A caller who is not in the team gets 404, the same answer as for an id that does not exist, so ids cannot be probed.
// A member who lacks the lead role gets 403: they already know the object exists. Admins pass for every team.
func (s *Server) authorize(w http.ResponseWriter, r *http.Request, teamID string, need teamLevel, what string) bool {
	principal := auth.FromContext(r.Context())
	access, err := s.store.TeamAccess(r.Context(), teamID, principal.ID)
	if err != nil {
		s.fail(w, r, err)
		return false
	}
	switch {
	case !access.Exists, access.Role == "" && !principal.IsAdmin():
		problem.Write(w, r, problem.NotFound("The "+what+" does not exist."))
		return false
	case need == levelLead && access.Role != "lead" && !principal.IsAdmin():
		problem.Write(w, r, problem.Forbidden("Only a team lead or an admin can do this."))
		return false
	}
	return true
}
