package main

import (
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
	// TODO 1: register the two routes. Send the text as text/plain; charset=utf-8.
	// TODO 2: write the middleware nosniff and return mux wrapped in it.
	return mux
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
