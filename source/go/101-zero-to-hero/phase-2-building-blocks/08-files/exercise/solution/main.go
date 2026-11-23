package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	// Restricted CSV: one label and one whole number, no quoting.
	text := "item,cost\ntea,3\nbread,2\nmilk,4\n"
	err := os.WriteFile("shopping.csv", []byte(text), 0600)
	if err != nil {
		fmt.Println("Write failed:", err)
		return
	}
	data, err := os.ReadFile("shopping.csv")
	if err != nil {
		fmt.Println("Read failed:", err)
		return
	}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
	if !scanner.Scan() || scanner.Text() != "item,cost" {
		fmt.Println("Missing or wrong header")
		return
	}
	total := 0
	for scanner.Scan() {
		fields := strings.Split(scanner.Text(), ",")
		if len(fields) != 2 {
			fmt.Println("Expected two fields")
			return
		}
		cost, err := strconv.Atoi(fields[1])
		if err != nil {
			fmt.Println("Invalid cost:", err)
			return
		}
		fmt.Println(fields[0], cost)
		total += cost
	}
	if scanner.Err() != nil {
		fmt.Println("Read lines failed:", scanner.Err())
		return
	}
	fmt.Println("Total:", total)
}
