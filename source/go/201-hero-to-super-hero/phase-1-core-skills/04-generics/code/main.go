package main

import "fmt"

func main() {
	words := []string{"go", "generics", "are", "typed"}

	lengths := Map(words, func(s string) int { return len(s) })
	fmt.Println(lengths)

	long := Filter(words, func(s string) bool { return len(s) > 2 })
	fmt.Println(long)

	fmt.Println(Sum(lengths))
	fmt.Println(Sum([]float64{1.5, 2.25}))

	type Celsius float64
	fmt.Println(Sum([]Celsius{20.5, 1.5}))

	fmt.Println(MaxOf(3, 9, 4), MaxOf("pear", "apple"))

	total := Reduce(words, 0, func(acc int, s string) int { return acc + len(s) })
	fmt.Println(total)

	stack := &Stack[string]{}
	stack.Push("a")
	stack.Push("b")
	top, ok := stack.Pop()
	fmt.Println(top, ok)
	_, ok = (&Stack[int]{}).Pop()
	fmt.Println(ok)

	set := NewSet("a", "b", "a")
	fmt.Println(set.Len(), set.Has("b"), set.Has("z"))
}
