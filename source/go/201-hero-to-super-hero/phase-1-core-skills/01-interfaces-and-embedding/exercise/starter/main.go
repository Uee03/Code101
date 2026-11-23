package main

import (
	"fmt"
	"os"
)

func main() {
	upper := UpperWriter{W: os.Stdout}
	fmt.Fprintln(upper, "hello, interfaces")

	counter := &CountingWriter{Writer: os.Stdout}
	fmt.Fprintln(counter, "count me")
	fmt.Fprintln(counter, "and me")
	fmt.Println("bytes written:", counter.Bytes)
}
