package domain

import (
	"errors"
	"strings"
	"unicode/utf8"
)

const MaxTitleLength = 120

var (
	ErrEmptyTitle   = errors.New("title must not be empty")
	ErrTitleTooLong = errors.New("title must be at most 120 characters")
	ErrNotFound     = errors.New("task not found")
)

// Task is the core business entity. It knows its own rules and nothing about
// HTTP, JSON, databases or logging.
type Task struct {
	ID    string
	Title string
	Done  bool
}

// NewTask validates the title and returns a task without an ID; the use case
// assigns the ID.
func NewTask(title string) (Task, error) {
	title = strings.TrimSpace(title)
	if title == "" {
		return Task{}, ErrEmptyTitle
	}
	if utf8.RuneCountInString(title) > MaxTitleLength {
		return Task{}, ErrTitleTooLong
	}
	return Task{Title: title}, nil
}

// Completed returns a copy of the task marked as done.
func (t Task) Completed() Task {
	t.Done = true
	return t
}
