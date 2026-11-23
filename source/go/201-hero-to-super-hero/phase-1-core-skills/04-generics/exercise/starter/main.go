package main

import "fmt"

func main() {
	ages := map[string]int{"cherry": 3, "apple": 1, "banana": 2}
	fmt.Println(SortedKeys(ages))

	words := []string{"a", "bb", "cc", "d"}
	fmt.Println(GroupBy(words, func(s string) int { return len(s) }))
}
