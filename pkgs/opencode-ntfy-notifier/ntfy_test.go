package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

func TestParseSession(t *testing.T) {
	tests := []struct {
		name    string
		message string
		want    string
	}{
		{"with hostname line", "Session: \"Explore opencode-ntfy integration (@explore subagent)\"\nHostname: host", "Explore opencode-ntfy integration (@explore subagent)"},
		{"quoted only", "Session: \"fix crash\"", "fix crash"},
		{"empty title", "Session: \"\"\nHostname: host", ""},
		{"spaces and punctuation", "Session: \"a: b, c (d) - e\"\nHostname: host", "a: b, c (d) - e"},
		{"unquoted title", "Session: fix crash", "fix crash"},
		{"permission line", "Session: \"agent\"\nHostname: host\nPermission: read", "agent"},
		{"no session line", "Hostname: host", ""},
		{"empty message", "", ""},
		{"leading whitespace", "  Session: \"x\"\nHostname: h", "x"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := parseSession(tt.message); got != tt.want {
				t.Errorf("parseSession(%q) = %q, want %q", tt.message, got, tt.want)
			}
		})
	}
}

func TestUrgency(t *testing.T) {
	tests := map[int]string{
		1: "low", 2: "low", 3: "normal", 4: "critical", 5: "critical",
	}
	for priority, want := range tests {
		if got := urgency(priority); got != want {
			t.Errorf("urgency(%d) = %q, want %q", priority, got, want)
		}
	}
}

func TestSubscriptionURL(t *testing.T) {
	got, err := subscriptionURL("https://ntfy.sh/", "mytopic", "")
	if err != nil {
		t.Fatal(err)
	}
	if want := "https://ntfy.sh/mytopic/json"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}

	got, err = subscriptionURL("https://ntfy.sh", "mytopic", "abc123")
	if err != nil {
		t.Fatal(err)
	}
	if want := "https://ntfy.sh/mytopic/json?since=abc123"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}

	if _, err := subscriptionURL("://bad", "t", ""); err == nil {
		t.Error("expected error for malformed server URL")
	}
}

func TestStreamFiltersEventsAndResumes(t *testing.T) {
	var gotSince string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotSince = r.URL.Query().Get("since")
		if r.URL.Path != "/mytopic/json" {
			t.Errorf("path = %q, want /mytopic/json", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/x-ndjson")
		fmt.Fprintln(w, `{"id":"m1","event":"open"}`)
		fmt.Fprintln(w, `{"id":"m1","event":"keepalive"}`)
		fmt.Fprintln(w, `not json at all`)
		fmt.Fprintln(w, `{"id":"m1","event":"message","title":"Agent Idle","message":"Session: \"one\"\nHostname: h","priority":4}`)
		fmt.Fprintln(w, `{"id":"m1","event":"message_delete"}`)
		fmt.Fprintln(w, `{"id":"m2","event":"message","message":"Session: \"two\"\nHostname: h","priority":3}`)
	}))
	defer server.Close()

	var got []ntfyEvent
	s := &ntfyStreamer{
		server: server.URL,
		topic:  "mytopic",
		client: server.Client(),
		logger: log.New(io.Discard, "", 0),
	}
	last, err := s.stream(context.Background(), "prev", func(ev ntfyEvent) {
		got = append(got, ev)
	})
	if err != nil && err != io.EOF {
		t.Fatalf("stream returned %v", err)
	}
	if gotSince != "prev" {
		t.Errorf("server saw since=%q, want prev", gotSince)
	}
	if last != "m2" {
		t.Errorf("last = %q, want m2", last)
	}
	if len(got) != 2 {
		t.Fatalf("handled %d events, want 2: %+v", len(got), got)
	}
	want := []ntfyEvent{
		{ID: "m1", Event: "message", Title: "Agent Idle", Message: "Session: \"one\"\nHostname: h", Priority: 4},
		{ID: "m2", Event: "message", Message: "Session: \"two\"\nHostname: h", Priority: 3},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("events = %+v, want %+v", got, want)
	}
}
