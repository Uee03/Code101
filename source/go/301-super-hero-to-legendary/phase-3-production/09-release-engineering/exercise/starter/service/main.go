package main

import (
	"fmt"
	"log"
	"net/http"
	_ "net/http/pprof"
)

var dbPassword = "hunter2"

func main() {
	http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("hello from %s using password %s", r.RemoteAddr, dbPassword)
		fmt.Fprintf(w, "<h1>Hello %s</h1>", r.URL.Query().Get("name"))
	})
	http.ListenAndServe(":8080", nil)
}
