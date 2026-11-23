package config

import (
	"io"
	"log/slog"
)

// Settings is what the program needs to start.
type Settings struct {
	Port  int
	Debug bool
}

// Load reads PORT and DEBUG through getenv.
//
//	PORT:  default 8080; when set it must be a whole number from 1 to 65535
//	DEBUG: default false; when set it must be a boolean that strconv.ParseBool accepts
//
// Any invalid value returns a non-nil error that names the variable.
func Load(getenv func(string) string) (Settings, error) {
	// TODO 1: apply the defaults, then the overrides, validating each.
	return Settings{}, nil
}

// NewQuietLogger returns a text logger that writes to w and leaves out the time attribute,
// so its output is identical on every run (handy in tests).
func NewQuietLogger(w io.Writer) *slog.Logger {
	// TODO 2: configure the handler so the "time" attribute is dropped.
	return slog.New(slog.NewTextHandler(w, nil))
}
