package main

import "fmt"

func main() {
	items := []string{"tea", "milk"}
	prices := map[string]int{"tea": 3, "milk": 4}
	// TODO: append another tea and sum the prices using range.
	fmt.Println("Items:", items, "Prices available:", len(prices))
}
