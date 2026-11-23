package main

import (
	"strings"
	"unicode/utf8"
)

// CreateBookRequest is what a client may send. Only these fields can be set from outside:
// ID and InternalNote are not here, so a client cannot choose them.
type CreateBookRequest struct {
	Title  string `json:"title"`
	Author string `json:"author"`
	Pages  int    `json:"pages"`
}

// BookResponse is what a client receives.
type BookResponse struct {
	ID     int    `json:"id"`
	Title  string `json:"title"`
	Author string `json:"author"`
	Pages  int    `json:"pages"`
}

// FieldError describes one invalid field.
type FieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// Validate checks business rules that JSON decoding cannot: required, length, range.
func (r CreateBookRequest) Validate() []FieldError {
	var errs []FieldError
	title := strings.TrimSpace(r.Title)
	switch {
	case title == "":
		errs = append(errs, FieldError{Field: "title", Message: "is required"})
	case utf8.RuneCountInString(title) > 200:
		errs = append(errs, FieldError{Field: "title", Message: "must be at most 200 characters"})
	}
	if strings.TrimSpace(r.Author) == "" {
		errs = append(errs, FieldError{Field: "author", Message: "is required"})
	}
	if r.Pages < 1 || r.Pages > 10000 {
		errs = append(errs, FieldError{Field: "pages", Message: "must be between 1 and 10000"})
	}
	return errs
}

func (r CreateBookRequest) toBook() Book {
	return Book{
		Title:  strings.TrimSpace(r.Title),
		Author: strings.TrimSpace(r.Author),
		Pages:  r.Pages,
	}
}

func toResponse(b Book) BookResponse {
	return BookResponse{ID: b.ID, Title: b.Title, Author: b.Author, Pages: b.Pages}
}
