package httpapi

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"example.com/tasksteams/internal/problem"
)

var uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

func isUUID(value string) bool { return uuidPattern.MatchString(value) }

// validator collects every field error of a request, so the client sees all of them at once.
type validator struct {
	errs []problem.FieldError
}

func (v *validator) add(pointer, detail string) {
	v.errs = append(v.errs, problem.FieldError{Pointer: pointer, Detail: detail})
}

// text trims the value, checks its length in characters (not bytes) and returns the trimmed text.
func (v *validator) text(pointer, value string, min, max int) string {
	value = strings.TrimSpace(value)
	if n := utf8.RuneCountInString(value); n < min || n > max {
		if min == 0 {
			v.add(pointer, fmt.Sprintf("must be at most %d characters", max))
		} else {
			v.add(pointer, fmt.Sprintf("must be between %d and %d characters", min, max))
		}
	}
	return value
}

func (v *validator) oneOf(pointer, value string, allowed ...string) {
	if !slices.Contains(allowed, value) {
		v.add(pointer, "must be one of: "+strings.Join(allowed, ", "))
	}
}

func (v *validator) matches(pointer, value string, pattern *regexp.Regexp, detail string) {
	if !pattern.MatchString(value) {
		v.add(pointer, detail)
	}
}

func (v *validator) uuid(pointer, value string) {
	if !isUUID(value) {
		v.add(pointer, "must be a UUID")
	}
}

// date parses a calendar date such as 2027-06-30.
func (v *validator) date(pointer, value string) (time.Time, bool) {
	parsed, err := time.Parse(time.DateOnly, value)
	if err != nil {
		v.add(pointer, "must be a date such as 2027-06-30")
		return time.Time{}, false
	}
	return parsed, true
}

// result returns nil when every check passed, otherwise the 422 problem with all errors.
func (v *validator) result() *problem.Problem {
	if len(v.errs) == 0 {
		return nil
	}
	return problem.Validation("One or more fields are invalid.", v.errs...)
}
