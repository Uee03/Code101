package main

import "fmt"

// healthURL turns a LISTEN_ADDR value into the address the container healthcheck calls on its own host.
// TODO: split the address with net.SplitHostPort, keep only the port and return
// "http://127.0.0.1:<port>/health" (use net.JoinHostPort so that the result is correct). Return "" when the
// address has no port.
func healthURL(listenAddr string) string {
	return ""
}

func main() {
	for _, addr := range []string{":8000", "0.0.0.0:8000", "127.0.0.1:9000", "[::]:8080", "8000"} {
		fmt.Printf("%-16q -> %q\n", addr, healthURL(addr))
	}
}
