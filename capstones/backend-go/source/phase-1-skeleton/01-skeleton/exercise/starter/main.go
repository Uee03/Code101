package main

import (
	"fmt"
	"regexp"
)

// FieldError mirrors problem.FieldError of the project.
type FieldError struct {
	Pointer string
	Detail  string
}

var keyPattern = regexp.MustCompile(`^[A-Z][A-Z0-9]{1,9}$`)

// validateProjectKey checks the key of a new project (schema ProjectCreate in the contract).
// TODO: return one FieldError with the pointer "/key" and the detail "invalid key" when the key does not match
// keyPattern, and nil when it does.
func validateProjectKey(key string) []FieldError {
	return nil
}

func main() {
	for _, key := range []string{"PLAT", "plat", "P", "TOOLONGKEY1", "A1"} {
		errs := validateProjectKey(key)
		if len(errs) == 0 {
			fmt.Printf("%-12s ok\n", key)
			continue
		}
		fmt.Printf("%-12s %s %s\n", key, errs[0].Pointer, errs[0].Detail)
	}
}
