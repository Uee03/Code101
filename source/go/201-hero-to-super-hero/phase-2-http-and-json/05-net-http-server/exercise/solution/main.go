package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

// newRouter must serve:
//
//	GET /hello         -> 200 and the text "hello, world"
//	GET /hello/{name}  -> 200 and the text "hello, " followed by the name
//
// and every response, including 404 and 405, must carry the header
// X-Content-Type-Options: nosniff, set by a middleware named nosniff.
func newRouter() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /hello", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprint(w, "hello, world")
	})
	mux.HandleFunc("GET /hello/{name}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprintf(w, "hello, %s", r.PathValue("name"))
	})
	return nosniff(mux)
}

func nosniff(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		next.ServeHTTP(w, r)
	})
}

func main() {
	srv := &http.Server{
		Addr:              "127.0.0.1:8080",
		Handler:           newRouter(),
		ReadHeaderTimeout: 5 * time.Second,
	}
	log.Printf("listening on http://%s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
