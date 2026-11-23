package main

import "fmt"

func main() {
	items := []string{"tea", "bread"}
	items = append(items, "milk")
	fmt.Println("Count:", len(items), "First:", items[0])
	for index, item := range items {
		fmt.Println(index, item)
	}
	prices := map[string]int{"tea": 3, "bread": 2, "milk": 4}
	total := 0
	for _, item := range items {
		total += prices[item]
	}
	fmt.Println("Total:", total)
	price, found := prices["coffee"]
	fmt.Println("Coffee:", price, "Found:", found)
	prices["coffee"] = 5
	delete(prices, "bread")
	fmt.Println("Coffee added:", prices["coffee"])
	_, found = prices["bread"]
	fmt.Println("Bread found:", found)
}
