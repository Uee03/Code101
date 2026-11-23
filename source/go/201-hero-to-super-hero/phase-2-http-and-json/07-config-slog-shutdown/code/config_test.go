package main

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func env(m map[string]string) func(string) string {
	return func(key string) string { return m[key] }
}

func TestLoadConfig(t *testing.T) {
	tests := []struct {
		name    string
		env     map[string]string
		want    Config
		wantErr string
	}{
		{"defaults", nil,
			Config{Addr: "127.0.0.1:8080", LogLevel: slog.LevelInfo, LogFormat: "text", ShutdownTimeout: 10 * time.Second}, ""},
		{"overrides",
			map[string]string{"APP_ADDR": ":9000", "APP_LOG_LEVEL": "debug", "APP_LOG_FORMAT": "json", "APP_SHUTDOWN_TIMEOUT": "2s"},
			Config{Addr: ":9000", LogLevel: slog.LevelDebug, LogFormat: "json", ShutdownTimeout: 2 * time.Second}, ""},
		{"bad level", map[string]string{"APP_LOG_LEVEL": "loud"}, Config{}, "APP_LOG_LEVEL"},
		{"bad format", map[string]string{"APP_LOG_FORMAT": "xml"}, Config{}, "APP_LOG_FORMAT"},
		{"zero timeout", map[string]string{"APP_SHUTDOWN_TIMEOUT": "0s"}, Config{}, "APP_SHUTDOWN_TIMEOUT"},
		{"not a duration", map[string]string{"APP_SHUTDOWN_TIMEOUT": "ten"}, Config{}, "APP_SHUTDOWN_TIMEOUT"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := LoadConfig(env(tc.env))
			if tc.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
					t.Fatalf("error %v, want one mentioning %s", err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tc.want {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
		})
	}
}

func TestLoadConfigReportsEveryProblem(t *testing.T) {
	_, err := LoadConfig(env(map[string]string{"APP_LOG_LEVEL": "loud", "APP_LOG_FORMAT": "xml"}))
	if err == nil || !strings.Contains(err.Error(), "APP_LOG_LEVEL") || !strings.Contains(err.Error(), "APP_LOG_FORMAT") {
		t.Fatalf("error %v should mention both settings", err)
	}
}

func TestRequestLogWritesOneStructuredRecord(t *testing.T) {
	var buf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&buf, nil))
	rec := httptest.NewRecorder()
	newHandler(logger).ServeHTTP(rec, httptest.NewRequest("GET", "/healthz", nil))

	var line map[string]any
	if err := json.Unmarshal(buf.Bytes(), &line); err != nil {
		t.Fatalf("log output is not one JSON object: %v (%q)", err, buf.String())
	}
	if line["msg"] != "request" || line["path"] != "/healthz" || line["status"] != float64(200) {
		t.Fatalf("unexpected record: %v", line)
	}
}
