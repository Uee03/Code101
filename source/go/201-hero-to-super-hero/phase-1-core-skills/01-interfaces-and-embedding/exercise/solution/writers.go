package main

import (
	"bytes"
	"io"
)

// UpperWriter writes everything it receives to W in upper case.
type UpperWriter struct {
	W io.Writer
}

func (u UpperWriter) Write(p []byte) (int, error) {
	if _, err := u.W.Write(bytes.ToUpper(p)); err != nil {
		return 0, err
	}
	return len(p), nil
}

// CountingWriter keeps in Bytes the total number of bytes written through it.
type CountingWriter struct {
	io.Writer
	Bytes int
}

func (c *CountingWriter) Write(p []byte) (int, error) {
	n, err := c.Writer.Write(p)
	c.Bytes += n
	return n, err
}
