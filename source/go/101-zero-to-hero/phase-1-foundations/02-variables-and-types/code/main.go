package main

import "fmt"

func main() {
	var item string = "notebook"
	quantity := 3
	var price float64 = 2.5
	var inStock bool = true
	const shop = "Corner Shop"
	quantity = quantity + 2
	var emptyCount int
	var emptyPrice float64
	var emptyName string
	var emptyFlag bool
	fmt.Println(shop, item)
	fmt.Println("Quantity:", quantity)
	fmt.Printf("Price: %.2f; in stock: %t\n", price, inStock)
	fmt.Printf("Zero values: %d %.1f %q %t\n", emptyCount, emptyPrice, emptyName, emptyFlag)
}
