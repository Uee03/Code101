package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("Bill amount (e.g. 80):")
	if !scanner.Scan() {
		fmt.Println("No bill input.")
		return
	}
	bill, err := strconv.ParseFloat(scanner.Text(), 64)
	if err != nil {
		fmt.Println("Use digits for the bill.")
		return
	}
	fmt.Println("Tip percent (e.g. 15):")
	if !scanner.Scan() {
		fmt.Println("No tip input.")
		return
	}
	percent, err := strconv.ParseFloat(scanner.Text(), 64)
	if err != nil {
		fmt.Println("Use digits for the percent.")
		return
	}
	fmt.Println("Number of people:")
	if !scanner.Scan() {
		fmt.Println("No people input.")
		return
	}
	people, err := strconv.Atoi(scanner.Text())
	if err != nil {
		fmt.Println("Use a whole number of people.")
		return
	}
	if bill < 0 || percent < 0 || people <= 0 {
		fmt.Println("Amounts must be nonnegative; people must be positive.")
		return
	}
	tip := bill * percent / 100
	total := bill + tip
	each := total / float64(people)
	fmt.Printf("Tip: %.2f\nTotal: %.2f\nEach: %.2f\n", tip, total, each)
	fmt.Println("Whole division:", 7/2, "Remainder:", 7%2)
}
