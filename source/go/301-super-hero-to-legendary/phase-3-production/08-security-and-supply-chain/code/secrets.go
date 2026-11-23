package main

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

// Secret is a string that never prints its value, in logs or with fmt.
// Call Reveal only at the point of use, for example when building a request.
type Secret string

func (Secret) String() string       { return "[redacted]" }
func (Secret) LogValue() slog.Value { return slog.StringValue("[redacted]") }
func (s Secret) Reveal() string     { return string(s) }

// ReadSecret returns the secret called name. If NAME_FILE is set, the value is
// read from that file (the convention used by Docker and Kubernetes secrets);
// otherwise it comes from the environment variable NAME.
func ReadSecret(name string) (Secret, error) {
	if path := os.Getenv(name + "_FILE"); path != "" {
		b, err := os.ReadFile(path)
		if err != nil {
			return "", fmt.Errorf("read %s_FILE: %w", name, err)
		}
		return nonEmpty(name, strings.TrimSpace(string(b)))
	}
	return nonEmpty(name, os.Getenv(name))
}

func nonEmpty(name, value string) (Secret, error) {
	if value == "" {
		return "", fmt.Errorf("secret %s is not set", name)
	}
	return Secret(value), nil
}
