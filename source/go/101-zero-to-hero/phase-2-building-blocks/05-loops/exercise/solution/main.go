package main

import "fmt"

func main() {
	start := 3
	for count := start; count > 0; count-- {
		fmt.Println(count)
	}
	fmt.Println("Go!")
}
