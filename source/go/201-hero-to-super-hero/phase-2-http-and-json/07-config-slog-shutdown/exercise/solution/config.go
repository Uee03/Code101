package config

import (
	"fmt"
	"io"
	"log/slog"
	"strconv"
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
	s := Settings{Port: 8080}
	if v := getenv("PORT"); v != "" {
		port, err := strconv.Atoi(v)
		if err != nil || port < 1 || port > 65535 {
			return Settings{}, fmt.Errorf("PORT %q: want a number from 1 to 65535", v)
		}
		s.Port = port
	}
	if v := getenv("DEBUG"); v != "" {
		debug, err := strconv.ParseBool(v)
		if err != nil {
			return Settings{}, fmt.Errorf("DEBUG %q: want true or false", v)
		}
		s.Debug = debug
	}
	return s, nil
}

// NewQuietLogger returns a text logger that writes to w and leaves out the time attribute,
// so its output is identical on every run (handy in tests).
func NewQuietLogger(w io.Writer) *slog.Logger {
	opts := &slog.HandlerOptions{
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if len(groups) == 0 && a.Key == slog.TimeKey {
				return slog.Attr{}
			}
			return a
		},
	}
	return slog.New(slog.NewTextHandler(w, opts))
}
