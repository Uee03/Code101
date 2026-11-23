package main

import (
	"fmt"
	"os"
)

func main() {
	mode := "safe"
	if len(os.Args) > 1 {
		mode = os.Args[1]
	}

	switch mode {
	case "safe":
		fmt.Println("mutex counter:", hammer(&MutexCounter{}, 8, 1000))
		fmt.Println("atomic counter:", hammer(&AtomicCounter{}, 8, 1000))
		fmt.Println("safe publish:", safePublish())

		cache := NewSafeCache()
		cache.Set("region", "eu-1")
		v, ok := cache.Get("region")
		fmt.Println("cache:", v, ok)
		fmt.Println("lazy config:", config()["region"])
	case "racy-counter":
		fmt.Println("racy counter:", hammer(&RacyCounter{}, 8, 1000), "(a correct counter would print 8000)")
	case "racy-publish":
		fmt.Printf("racy publish: %q\n", racyPublish())
	case "racy-map":
		racyMapWrites()
		fmt.Println("racy map: finished without a crash this time")
	default:
		fmt.Fprintf(os.Stderr, "unknown mode %q: use safe, racy-counter, racy-publish or racy-map\n", mode)
		os.Exit(2)
	}
}
