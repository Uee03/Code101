package httpapi

import (
	"net/http"
	"strconv"
	"strings"

	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

const (
	defaultLimit = 25
	maxLimit     = 100
)

// pageParams reads limit and cursor. The cursor stays opaque here; the store decodes it.
func pageParams(r *http.Request) (store.PageParams, *problem.Problem) {
	query := r.URL.Query()
	params := store.PageParams{Limit: defaultLimit, Cursor: query.Get("cursor")}
	if raw := query.Get("limit"); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 1 || n > maxLimit {
			return params, problem.BadRequest("limit must be a whole number from 1 to 100.")
		}
		params.Limit = n
	}
	if len(params.Cursor) > 512 {
		return params, problem.BadRequest(store.ErrBadCursor.Message)
	}
	return params, nil
}

// sortParam returns the sort query parameter; the first allowed value is the default.
func sortParam(r *http.Request, allowed ...string) (string, *problem.Problem) {
	value := r.URL.Query().Get("sort")
	if value == "" {
		return allowed[0], nil
	}
	for _, candidate := range allowed {
		if value == candidate {
			return value, nil
		}
	}
	return "", problem.BadRequest("sort must be one of: " + strings.Join(allowed, ", ") + ".")
}

// textParam returns a free-text query parameter such as q, limited to max characters.
func textParam(r *http.Request, name string, max int) (string, *problem.Problem) {
	value := strings.TrimSpace(r.URL.Query().Get(name))
	if len([]rune(value)) > max {
		return "", problem.BadRequest(name + " must be at most " + strconv.Itoa(max) + " characters.")
	}
	return value, nil
}

// pathID reads a UUID from the URL. Text that is not a UUID cannot be the id of anything, so the answer is 404.
func pathID(w http.ResponseWriter, r *http.Request, name string) (string, bool) {
	id := r.PathValue(name)
	if !isUUID(id) {
		problem.Write(w, r, problem.NotFound("The resource does not exist."))
		return "", false
	}
	return id, true
}

type pageInfo struct {
	Limit      int     `json:"limit"`
	NextCursor *string `json:"nextCursor"` // null on the last page
}

type pageDTO[T any] struct {
	Items []T      `json:"items"`
	Page  pageInfo `json:"page"`
}

// toPage converts a page of store items into the contract's page object.
func toPage[S, D any](page store.Page[S], limit int, convert func(S) D) pageDTO[D] {
	out := pageDTO[D]{Items: make([]D, 0, len(page.Items)), Page: pageInfo{Limit: limit}}
	for _, item := range page.Items {
		out.Items = append(out.Items, convert(item))
	}
	if page.NextCursor != "" {
		out.Page.NextCursor = &page.NextCursor
	}
	return out
}
