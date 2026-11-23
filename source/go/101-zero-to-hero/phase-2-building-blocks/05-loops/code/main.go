package main

import "fmt"

func main() {
	total := 0
	for day := 1; day <= 3; day++ {
		total += day
		fmt.Println("Day:", day)
	}
	fmt.Println("Total:", total)
	remaining := 2
	for remaining > 0 {
		fmt.Println("Remaining:", remaining)
		remaining--
	}
	turn := 0
	for {
		turn++
		if turn == 2 {
			continue
		}
		if turn > 3 {
			break
		}
		fmt.Println("Turn:", turn)
	}
}
