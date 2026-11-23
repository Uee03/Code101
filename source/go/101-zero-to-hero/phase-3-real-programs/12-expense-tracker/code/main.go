package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	if err := selfCheck(); err != nil {
		fmt.Println("Self-check failed:", err)
		return
	}
	fmt.Println("Self-check: OK")
	path := "expenses.csv"
	expenses, err := load(path)
	if err != nil {
		fmt.Println("Load failed:", err)
		return
	}
	fmt.Println("Loaded:", len(expenses))
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Command: add, list, total, quit")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
			} else {
				fmt.Println("Input ended. Use quit to save next time.")
			}
			return
		}
		switch scanner.Text() {
		case "add":
			fmt.Println("Label (no commas or quotes):")
			if !scanner.Scan() {
				fmt.Println("Input ended before label.")
				return
			}
			label := scanner.Text()
			fmt.Println("Amount in cents (350 means 3.50):")
			if !scanner.Scan() {
				fmt.Println("Input ended before amount.")
				return
			}
			expense, err := parseRow(label + "," + scanner.Text())
			if err != nil {
				fmt.Println("Not added:", err)
				continue
			}
			if len(expenses) >= 1000 {
				fmt.Println("Maximum 1000 expenses")
				continue
			}
			expenses = append(expenses, expense)
			fmt.Println("Added:", expense.String())
		case "list":
			for index, expense := range expenses {
				fmt.Println(index+1, expense.String())
			}
		case "total":
			total := 0
			for _, expense := range expenses {
				total += expense.Cents
			}
			fmt.Println("Total:", money(total))
		case "quit":
			if err := save(path, expenses); err != nil {
				fmt.Println("Save failed:", err)
				continue
			}
			fmt.Println("Saved:", len(expenses), "expenses")
			return
		default:
			fmt.Println("Unknown command")
		}
	}
}
