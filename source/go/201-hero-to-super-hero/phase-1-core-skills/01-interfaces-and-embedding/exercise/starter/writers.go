package main

import "io"

// UpperWriter must write everything it receives to W in upper case.
type UpperWriter struct {
	W io.Writer
}

// TODO 1: make this Write method do its job: upper-case the bytes, write them to W,
// and report how many bytes of p were consumed (the io.Writer contract).
func (u UpperWriter) Write(p []byte) (int, error) {
	return 0, nil
}

// CountingWriter must keep in Bytes the total number of bytes written through it.
type CountingWriter struct {
	io.Writer
	Bytes int
}

// TODO 2: declare a Write method on *CountingWriter that forwards to the embedded Writer
// and adds the number of bytes actually written to Bytes. Expected last line of output: bytes written: 16
