package main

import (
	"bytes"
	"errors"
	"testing"
)

func TestWelcomeSendsToEveryone(t *testing.T) {
	fake := &FakeSender{}
	if err := Welcome(fake, []string{"ada", "linus"}); err != nil {
		t.Fatalf("Welcome returned %v", err)
	}
	if len(fake.Sent) != 2 {
		t.Fatalf("sent %d messages, want 2", len(fake.Sent))
	}
}

func TestCountingSenderForwardsAndCounts(t *testing.T) {
	fake := &FakeSender{}
	counted := &CountingSender{Sender: fake}
	_ = Welcome(counted, []string{"ada"})
	if counted.Count != 1 || len(fake.Sent) != 1 {
		t.Fatalf("count=%d forwarded=%d, want 1 and 1", counted.Count, len(fake.Sent))
	}
}

type brokenSender struct{ err error }

func (b brokenSender) Send(string, string) error { return b.err }

func TestWelcomeWrapsTheSenderError(t *testing.T) {
	boom := errors.New("boom")
	err := Welcome(brokenSender{err: boom}, []string{"ada"})
	if !errors.Is(err, boom) {
		t.Fatalf("error %v does not wrap boom", err)
	}
}

func TestConsoleSenderFormat(t *testing.T) {
	var buf bytes.Buffer
	_ = ConsoleSender{Out: &buf}.Send("ada", "hi")
	want := "to=ada body=\"hi\"\n"
	if buf.String() != want {
		t.Fatalf("got %q, want %q", buf.String(), want)
	}
}
