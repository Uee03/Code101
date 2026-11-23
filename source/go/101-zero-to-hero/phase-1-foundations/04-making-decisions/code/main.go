package main

import "fmt"

func main() {
	age := 30
	hasTicket := true
	fmt.Println("5 > 3:", 5 > 3)
	fmt.Println("5 < 3:", 5 < 3)
	fmt.Println("5 == 5:", 5 == 5)
	fmt.Println("5 != 5:", 5 != 5)
	fmt.Println("5 >= 5:", 5 >= 5)
	fmt.Println("5 <= 5:", 5 <= 5)
	fmt.Println("Adult with ticket:", age >= 18 && hasTicket)
	fmt.Println("Child or ticket:", age < 18 || hasTicket)
	fmt.Println("No ticket:", !hasTicket)
	if age < 0 {
		fmt.Println("Invalid age")
	} else if age < 5 {
		fmt.Println("Ticket: free")
	} else if age < 18 {
		fmt.Println("Ticket: 5.00")
	} else {
		fmt.Println("Ticket: 10.00")
	}
	day := "Saturday"
	switch day {
	case "Saturday", "Sunday":
		fmt.Println("Weekend hours")
	default:
		fmt.Println("Weekday hours")
	}
}
