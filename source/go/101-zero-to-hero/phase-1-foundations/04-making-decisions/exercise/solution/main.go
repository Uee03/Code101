package main

import "fmt"

func main() {
	score := 60
	if score < 0 || score > 100 {
		fmt.Println("Invalid score")
	} else if score < 50 {
		fmt.Println("Fail")
	} else if score < 75 {
		fmt.Println("Pass")
	} else {
		fmt.Println("Merit")
	}
}
