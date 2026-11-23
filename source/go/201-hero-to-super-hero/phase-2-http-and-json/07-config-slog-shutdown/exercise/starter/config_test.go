package config

import (
	"bytes"
	"strings"
	"testing"
)

func env(m map[string]string) func(string) string {
	return func(key string) string { return m[key] }
}

func TestLoad(t *testing.T) {
	tests := []struct {
		name    string
		env     map[string]string
		want    Settings
		wantErr string
	}{
		{"defaults", nil, Settings{Port: 8080, Debug: false}, ""},
		{"overrides", map[string]string{"PORT": "9000", "DEBUG": "true"}, Settings{Port: 9000, Debug: true}, ""},
		{"port is not a number", map[string]string{"PORT": "abc"}, Settings{}, "PORT"},
		{"port is zero", map[string]string{"PORT": "0"}, Settings{}, "PORT"},
		{"port is too large", map[string]string{"PORT": "70000"}, Settings{}, "PORT"},
		{"debug is not a boolean", map[string]string{"DEBUG": "maybe"}, Settings{}, "DEBUG"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := Load(env(tc.env))
			if tc.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
					t.Fatalf("error %v, want one mentioning %s", err, tc.wantErr)
				}
				return
			}
			if err != nil || got != tc.want {
				t.Fatalf("got %+v, %v; want %+v", got, err, tc.want)
			}
		})
	}
}

func TestQuietLoggerHasNoTime(t *testing.T) {
	var buf bytes.Buffer
	NewQuietLogger(&buf).Info("hello", "user", "ada")
	want := "level=INFO msg=hello user=ada\n"
	if buf.String() != want {
		t.Fatalf("got %q, want %q", buf.String(), want)
	}
}
