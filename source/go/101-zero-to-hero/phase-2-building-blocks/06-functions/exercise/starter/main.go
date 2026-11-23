package main

import "fmt"

func rectangle(width int, height int) (int, int) {
	area := width * height
	perimeter := 2 * (width + height)
	return area, perimeter
}

func split(total float64, people int) (each float64, valid bool) {
	if people <= 0 {
		return 0, false
	}
	// TODO: include a 6.00 delivery charge before dividing.
	each = 0
	valid = true
	return each, valid
}

func main() {
	area, perimeter := rectangle(3, 4)
	fmt.Println("Area:", area, "Perimeter:", perimeter)
	each, valid := split(90, 3)
	fmt.Printf("Each: %.2f; valid: %t\n", each, valid)
}
