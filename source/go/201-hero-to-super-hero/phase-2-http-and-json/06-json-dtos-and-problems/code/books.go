package main

import (
	"fmt"
	"net/http"
	"strconv"
)

type api struct {
	store *Store
}

func (a *api) createBook(w http.ResponseWriter, r *http.Request) {
	var req CreateBookRequest
	if p, ok := decodeJSON(w, r, &req); !ok {
		writeProblem(w, r, p)
		return
	}
	if errs := req.Validate(); len(errs) > 0 {
		writeProblem(w, r, validationFailed(errs))
		return
	}
	book := a.store.Create(req.toBook())
	w.Header().Set("Location", "/books/"+strconv.Itoa(book.ID))
	writeJSON(w, http.StatusCreated, toResponse(book))
}

func (a *api) getBook(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeProblem(w, r, badRequest("id must be a number."))
		return
	}
	book, ok := a.store.Get(id)
	if !ok {
		writeProblem(w, r, notFound(fmt.Sprintf("No book with id %d.", id)))
		return
	}
	writeJSON(w, http.StatusOK, toResponse(book))
}
