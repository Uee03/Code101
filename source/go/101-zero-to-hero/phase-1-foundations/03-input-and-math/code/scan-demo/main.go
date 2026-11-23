package main

import "fmt"

func main() {
	var people int
	fmt.Println("People (one whole number):")
	_, err := fmt.Scan(&people)
	if err != nil {
		fmt.Println("Use a whole number.")
		return
	}
	fmt.Println("People:", people)
}
