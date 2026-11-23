package main

import (
	"fmt"
	"net"
)

// healthURL turns a LISTEN_ADDR value into the address the container healthcheck calls on its own host.
func healthURL(listenAddr string) string {
	_, port, err := net.SplitHostPort(listenAddr)
	if err != nil {
		return ""
	}
	return "http://" + net.JoinHostPort("127.0.0.1", port) + "/health"
}

func main() {
	for _, addr := range []string{":8000", "0.0.0.0:8000", "127.0.0.1:9000", "[::]:8080", "8000"} {
		fmt.Printf("%-16q -> %q\n", addr, healthURL(addr))
	}
}
