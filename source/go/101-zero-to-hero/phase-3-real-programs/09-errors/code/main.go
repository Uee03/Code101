package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
)

func parseAmount(text string) (int, error) {
	amount, err := strconv.Atoi(text)
	if err != nil {
		return 0, fmt.Errorf("amount %q: %w", text, err)
	}
	if amount <= 0 {
		return 0, errors.New("amount must be positive")
	}
	return amount, nil
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Amount in whole units:")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
			} else {
				fmt.Println("Input ended.")
			}
			return
		}
		amount, err := parseAmount(scanner.Text())
		if err != nil {
			fmt.Println("Try again:", err)
			continue
		}
		fmt.Println("Accepted:", amount)
		break
	}
}
