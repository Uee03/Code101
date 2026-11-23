package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"example.com/code101/go201/lesson09/auth"
)

const (
	issuer   = "https://issuer.example.com"
	audience = "go201-api"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	svc, err := auth.NewService(os.Getenv("AUTH_SECRET"), issuer, audience)
	if err != nil {
		return fmt.Errorf("AUTH_SECRET: %w", err)
	}
	if len(args) > 0 && args[0] == "mint" {
		return mint(svc, args[1:])
	}
	return serve(svc)
}

// mint prints a token for development: go run . mint <subject> [role ...]
func mint(svc *auth.Service, args []string) error {
	if len(args) < 1 {
		return errors.New("usage: go run . mint <subject> [role ...]")
	}
	token, err := svc.Mint(args[0], args[1:], time.Hour)
	if err != nil {
		return err
	}
	fmt.Println(token)
	return nil
}

func serve(svc *auth.Service) error {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /public", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "anyone can read this")
	})
	mux.Handle("GET /me", svc.Middleware(http.HandlerFunc(me)))
	mux.Handle("GET /admin", svc.Middleware(auth.RequireRole("admin")(http.HandlerFunc(admin))))

	srv := &http.Server{
		Addr:              "127.0.0.1:8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("listening on http://%s", srv.Addr)
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

func me(w http.ResponseWriter, r *http.Request) {
	claims, _ := auth.FromContext(r.Context())
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(struct {
		Sub   string   `json:"sub"`
		Roles []string `json:"roles"`
	}{Sub: claims.Subject, Roles: claims.Roles})
}

func admin(w http.ResponseWriter, r *http.Request) {
	claims, _ := auth.FromContext(r.Context())
	fmt.Fprintf(w, "welcome, admin %s\n", claims.Subject)
}
