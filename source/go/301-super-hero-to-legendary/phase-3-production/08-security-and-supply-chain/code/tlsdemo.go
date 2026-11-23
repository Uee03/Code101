package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httptest"
	"time"
)

// mtlsDemo starts a server that requires a client certificate and calls it
// twice: once with a certificate from the trusted CA, once without.
func mtlsDemo() (with string, without string, err error) {
	ca, err := NewCA()
	if err != nil {
		return "", "", err
	}
	serverCert, err := ca.Issue("inventory.internal", []string{"inventory.internal"}, []net.IP{net.ParseIP("127.0.0.1")}, x509.ExtKeyUsageServerAuth)
	if err != nil {
		return "", "", err
	}
	clientCert, err := ca.Issue("billing-service", nil, nil, x509.ExtKeyUsageClientAuth)
	if err != nil {
		return "", "", err
	}

	srv := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The caller's identity comes from the verified certificate, not from a header.
		fmt.Fprintf(w, "hello %s", r.TLS.PeerCertificates[0].Subject.CommonName)
	}))
	srv.Config.ErrorLog = log.New(io.Discard, "", 0) // keep expected handshake failures quiet
	srv.TLS = &tls.Config{
		Certificates: []tls.Certificate{serverCert},
		ClientAuth:   tls.RequireAndVerifyClientCert,
		ClientCAs:    ca.Pool,
		MinVersion:   tls.VersionTLS13,
	}
	srv.StartTLS()
	defer srv.Close()

	with, err = get(srv.URL, ca, &clientCert)
	if err != nil {
		return "", "", err
	}
	if _, err := get(srv.URL, ca, nil); err != nil {
		without = "rejected"
	} else {
		without = "accepted (this is a bug)"
	}
	return with, without, nil
}

// get calls url, trusting only ca, and presenting cert when it is not nil.
func get(url string, ca *PKI, cert *tls.Certificate) (string, error) {
	cfg := &tls.Config{RootCAs: ca.Pool, MinVersion: tls.VersionTLS13}
	if cert != nil {
		cfg.Certificates = []tls.Certificate{*cert}
	}
	client := &http.Client{
		Timeout:   5 * time.Second,
		Transport: &http.Transport{TLSClientConfig: cfg},
	}
	defer client.CloseIdleConnections()

	resp, err := client.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<10))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%d %s", resp.StatusCode, body), nil
}
