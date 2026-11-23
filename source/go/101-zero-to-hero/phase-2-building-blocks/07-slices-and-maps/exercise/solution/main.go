package main

import "fmt"

func main() {
	items := []string{"tea", "milk"}
	prices := map[string]int{"tea": 3, "milk": 4}
	items = append(items, "tea")
	total := 0
	for _, item := range items {
		total += prices[item]
	}
	fmt.Println("Total:", total)
}
