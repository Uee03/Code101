package main

import (
	"fmt"
	"io"
)

// Sender is declared here, next to its user: the consumer states what it needs.
type Sender interface {
	Send(to, body string) error
}

// ConsoleSender writes each message to any io.Writer.
type ConsoleSender struct {
	Out io.Writer
}

func (c ConsoleSender) Send(to, body string) error {
	_, err := fmt.Fprintf(c.Out, "to=%s body=%q\n", to, body)
	return err
}

// FakeSender records messages in memory; tests and demos use it instead of a real channel.
type FakeSender struct {
	Sent []string
}

func (f *FakeSender) Send(to, body string) error {
	f.Sent = append(f.Sent, to+": "+body)
	return nil
}

func (f *FakeSender) String() string {
	return fmt.Sprintf("fake(%d sent)", len(f.Sent))
}

// CountingSender embeds a Sender, so it already has a Send method.
// Declaring its own Send overrides the promoted one and adds counting.
type CountingSender struct {
	Sender
	Count int
}

func (c *CountingSender) Send(to, body string) error {
	c.Count++
	return c.Sender.Send(to, body)
}

// Compile-time checks: the build fails if a type stops satisfying Sender.
var (
	_ Sender = ConsoleSender{}
	_ Sender = (*FakeSender)(nil)
	_ Sender = (*CountingSender)(nil)
)

// Welcome accepts the interface, so it works with every Sender above.
func Welcome(s Sender, names []string) error {
	for _, name := range names {
		if err := s.Send(name, "welcome, "+name); err != nil {
			return fmt.Errorf("welcome %s: %w", name, err)
		}
	}
	return nil
}

// describe asks for an optional ability with a type assertion.
func describe(s Sender) string {
	if st, ok := s.(fmt.Stringer); ok {
		return st.String()
	}
	return "anonymous sender"
}

// lookup shows the typed-nil trap: the interface value holds a type, so it is not nil.
func lookup(found bool) Sender {
	var f *FakeSender
	if found {
		f = &FakeSender{}
	}
	return f
}
