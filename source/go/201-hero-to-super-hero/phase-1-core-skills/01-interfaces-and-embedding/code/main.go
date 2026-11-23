package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	console := ConsoleSender{Out: os.Stdout}
	counted := &CountingSender{Sender: console}
	if err := Welcome(counted, []string{"ada", "linus"}); err != nil {
		fmt.Println("error:", err)
		return
	}
	fmt.Println("sent:", counted.Count)

	fake := &FakeSender{}
	_ = Welcome(fake, []string{"grace"})
	fmt.Println(strings.Join(fake.Sent, ";"))

	fmt.Println(describe(console))
	fmt.Println(describe(fake))
	fmt.Println(describe(counted))

	fmt.Println(lookup(false) == nil)
}
