package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"net/http"
	netpprof "net/http/pprof"
	"os"
	"os/signal"
	"runtime"
	"runtime/pprof"
	"strings"
	"time"

	"example.com/code101/go301/l03/wordfreq"
)

const sample = "The quick brown fox jumps over the lazy dog. The dog did not mind; the fox did."

var workload = strings.Repeat(sample+" ", 200)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run() error {
	cpuProfile := flag.String("cpuprofile", "", "write a CPU profile to this file")
	memProfile := flag.String("memprofile", "", "write an allocation profile to this file")
	rounds := flag.Int("n", 0, "count a larger text this many times (0 prints the top words once)")
	naive := flag.Bool("naive", false, "use the slow implementation")
	debugAddr := flag.String("debug-addr", "", "serve pprof here and run until Ctrl+C, for example 127.0.0.1:6060")
	flag.Parse()

	count := wordfreq.Count
	if *naive {
		count = wordfreq.CountNaive
	}

	if *cpuProfile != "" {
		f, err := os.Create(*cpuProfile)
		if err != nil {
			return err
		}
		defer f.Close()
		if err := pprof.StartCPUProfile(f); err != nil {
			return err
		}
		defer pprof.StopCPUProfile()
	}

	switch {
	case *debugAddr != "":
		return serveAndLoad(*debugAddr, count)
	case *rounds > 0:
		for range *rounds {
			count(workload)
		}
	default:
		for _, e := range wordfreq.Top(count(sample), 5) {
			fmt.Println(e.Word, e.Count)
		}
	}

	if *memProfile != "" {
		return writeAllocProfile(*memProfile)
	}
	return nil
}

func writeAllocProfile(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	runtime.GC() // bring the statistics up to date before writing
	return pprof.Lookup("allocs").WriteTo(f, 0)
}

// serveAndLoad exposes the pprof handlers on an explicit mux (not the default
// one) and keeps the program busy so there is something to profile.
func serveAndLoad(addr string, count func(string) map[string]int) error {
	mux := http.NewServeMux()
	mux.HandleFunc("/debug/pprof/", netpprof.Index)
	mux.HandleFunc("/debug/pprof/cmdline", netpprof.Cmdline)
	mux.HandleFunc("/debug/pprof/profile", netpprof.Profile)
	mux.HandleFunc("/debug/pprof/symbol", netpprof.Symbol)
	mux.HandleFunc("/debug/pprof/trace", netpprof.Trace)

	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintln(os.Stderr, "debug server:", err)
		}
	}()
	defer srv.Close()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	fmt.Println("serving pprof on http://" + addr + "/debug/pprof/ ; press Ctrl+C to stop")
	for ctx.Err() == nil {
		count(workload)
	}
	return nil
}
