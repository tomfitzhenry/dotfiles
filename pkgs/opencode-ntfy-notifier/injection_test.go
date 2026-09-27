package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// namedPayload is a labelled adversarial session name.
type namedPayload struct {
	name  string
	value string
}

// injectionPayloads are attacker-controlled session names that try to break out
// of the data sinks (niri JSON IPC, logs, URLs). Newlines and quotes are the
// most interesting; shell metacharacters must stay inert because nothing ever
// reaches a shell.
func injectionPayloads() []namedPayload {
	return []namedPayload{
		{"json structure injection", `x"}},{"Action":{"FocusWorkspace":{"reference":{"Name":"evil`},
		{"embedded newline", "a\n{\"Action\":{\"FocusWorkspace\":{\"reference\":{\"Name\":\"pwned\"}}}}"},
		{"embedded crlf", "a\r\n{\"Action\":{\"FocusWorkspace\":{\"reference\":{\"Name\":\"pwned\"}}}}"},
		{"semicolon shell", `"; rm -rf / #`},
		{"backticks", "`id`"},
		{"command substitution", "$(id)"},
		{"ifs expansion", "${IFS}"},
		{"embedded nul", "a\x00b"},
		{"line separator", "a\u2028b"},
		{"paragraph separator", "a\u2029b"},
		{"embedded tab", "a\tb"},
		{"very long", strings.Repeat("A", 200000)},
		{"dash rf", "-rf"},
		{"dash dash help", "--help"},
		{"numeric looking", "3"},
		{"leading and trailing spaces", "  spaced  "},
		{"quoted", `"quoted"`},
		{"unicode", "wörk späce \U0001F600"},
	}
}

// assertFocusRequest decodes raw as a FocusWorkspace request and asserts that
// the only thing it carries is reference.Name == wantName, with no Index/Id and
// no extra keys anywhere in the envelope.
func assertFocusRequest(t *testing.T, raw json.RawMessage, wantName string) {
	t.Helper()

	if bytes.Contains(raw, []byte("\n")) {
		t.Errorf("request contains a literal newline: %q", raw)
	}
	if bytes.Contains(raw, []byte("\r")) {
		t.Errorf("request contains a literal carriage return: %q", raw)
	}

	var top map[string]json.RawMessage
	if err := json.Unmarshal(raw, &top); err != nil {
		t.Fatalf("decode focus request %s: %v", raw, err)
	}
	if len(top) != 1 {
		t.Errorf("request has %d top-level keys, want 1: %s", len(top), raw)
	}
	var action map[string]json.RawMessage
	if err := json.Unmarshal(top["Action"], &action); err != nil {
		t.Fatalf("decode Action in %s: %v", raw, err)
	}
	if len(action) != 1 {
		t.Errorf("Action has %d keys, want 1: %s", len(action), raw)
	}
	var fw map[string]json.RawMessage
	if err := json.Unmarshal(action["FocusWorkspace"], &fw); err != nil {
		t.Fatalf("decode FocusWorkspace in %s: %v", raw, err)
	}
	if len(fw) != 1 {
		t.Errorf("FocusWorkspace has %d keys, want 1: %s", len(fw), raw)
	}
	var ref map[string]json.RawMessage
	if err := json.Unmarshal(fw["reference"], &ref); err != nil {
		t.Fatalf("decode reference in %s: %v", raw, err)
	}
	if len(ref) != 1 {
		t.Errorf("reference has %d keys, want only Name: %s", len(ref), raw)
	}
	for _, bad := range []string{"Index", "Id", "name"} {
		if _, ok := ref[bad]; ok {
			t.Errorf("reference contains %q: %s", bad, raw)
		}
	}
	var name string
	if err := json.Unmarshal(ref["Name"], &name); err != nil {
		t.Fatalf("decode reference.Name in %s: %v", raw, err)
	}
	if name != wantName {
		t.Errorf("reference.Name = %q, want the full payload %q", name, wantName)
	}
}

// focusRequests returns the recorded requests that are not the workspace list.
func focusRequests(reqs []json.RawMessage) []json.RawMessage {
	var out []json.RawMessage
	for _, r := range reqs {
		if string(r) == `"Workspaces"` {
			continue
		}
		out = append(out, r)
	}
	return out
}

// TestFocusWorkspaceRequestBuilderByValue unit-tests the request encoder.
// encoding/json must put the whole attacker string inside one JSON string and
// never emit a literal newline; the framing newline is appended exactly once.
func TestFocusWorkspaceRequestBuilderByValue(t *testing.T) {
	for _, p := range injectionPayloads() {
		t.Run(p.name, func(t *testing.T) {
			raw, err := json.Marshal(focusWorkspaceRequest(p.value))
			if err != nil {
				t.Fatalf("marshal: %v", err)
			}
			if bytes.ContainsAny(raw, "\n\r") {
				t.Errorf("marshalled request contains a raw newline: %q", raw)
			}

			line := append(append([]byte(nil), raw...), '\n')
			if got := bytes.Count(line, []byte("\n")); got != 1 {
				t.Errorf("framed request has %d newlines, want 1: %q", got, line)
			}
			if line[len(line)-1] != '\n' {
				t.Errorf("framed request does not end in a newline: %q", line)
			}

			assertFocusRequest(t, raw, p.value)
		})
	}
}

// TestFocusWorkspacePayloadsAreNotInjectable drives the real niri socket with
// every nasty payload and asserts the fake niri receives a single focus request
// whose Name is the entire payload. A structural escape or newline split would
// show up as a truncated Name or extra requests.
func TestFocusWorkspacePayloadsAreNotInjectable(t *testing.T) {
	for _, p := range injectionPayloads() {
		t.Run(p.name, func(t *testing.T) {
			f := startFakeNiri(t, func(request json.RawMessage) any {
				if string(request) == `"Workspaces"` {
					return workspacesReply(p.value)
				}
				return map[string]any{"Ok": "Handled"}
			})
			t.Setenv("NIRI_SOCKET", f.path)

			if err := newNiriFocuser().focusWorkspace(p.value); err != nil {
				t.Fatalf("focusWorkspace(%q): %v", p.value, err)
			}

			reqs := f.received()
			if len(reqs) != 2 {
				t.Fatalf("got %d requests, want exactly 2 (Workspaces + focus): %v", len(reqs), reqs)
			}
			focus := focusRequests(reqs)
			if len(focus) != 1 {
				t.Fatalf("got %d focus requests, want 1: %v", len(focus), reqs)
			}
			assertFocusRequest(t, focus[0], p.value)
		})
	}
}

// TestFocusWorkspaceNumericNameStaysName pins the reason for the explicit Name
// variant: "3" must be a workspace *name*, never an Index.
func TestFocusWorkspaceNumericNameStaysName(t *testing.T) {
	f := startFakeNiri(t, func(request json.RawMessage) any {
		if string(request) == `"Workspaces"` {
			return workspacesReply("3")
		}
		return map[string]any{"Ok": "Handled"}
	})
	t.Setenv("NIRI_SOCKET", f.path)

	if err := newNiriFocuser().focusWorkspace("3"); err != nil {
		t.Fatalf("focusWorkspace(\"3\"): %v", err)
	}
	focus := focusRequests(f.received())
	if len(focus) != 1 {
		t.Fatalf("got %d focus requests, want 1", len(focus))
	}
	assertFocusRequest(t, focus[0], "3")
}

// TestSessionNameDoesNotReachShell proves shell metacharacters in a session are
// inert: focusing a workspace whose name contains a would-be command must not
// create the marker file. A static check locks in the no-shell design.
func TestSessionNameDoesNotReachShell(t *testing.T) {
	marker := filepath.Join(t.TempDir(), "pwned")
	payloads := []string{
		"x; touch " + marker,
		"x$(touch " + marker + ")",
		"x`touch " + marker + "`",
		"x && touch " + marker,
		"x | touch " + marker,
		"x > " + marker,
	}

	for _, p := range payloads {
		f := startFakeNiri(t, func(request json.RawMessage) any {
			if string(request) == `"Workspaces"` {
				return workspacesReply(p)
			}
			return map[string]any{"Ok": "Handled"}
		})
		t.Setenv("NIRI_SOCKET", f.path)
		if err := newNiriFocuser().focusWorkspace(p); err != nil {
			t.Fatalf("focusWorkspace(%q): %v", p, err)
		}
	}

	if _, err := os.Stat(marker); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("shell payload created %s (stat err = %v); a session name reached a shell", marker, err)
	}
}

// TestNoShellOutInProductionSource is a static assertion that the production
// code never shells out, so no session-name escaping is needed for a shell.
// Test files are excluded because the D-Bus integration test legitimately runs
// dbus-daemon.
func TestNoShellOutInProductionSource(t *testing.T) {
	forbidden := []string{`"os/exec"`, "exec.Command", "sh -c", "/bin/sh", "/bin/bash"}
	files, err := filepath.Glob("*.go")
	if err != nil {
		t.Fatal(err)
	}
	checked := 0
	for _, f := range files {
		if strings.HasSuffix(f, "_test.go") {
			continue
		}
		checked++
		data, err := os.ReadFile(f)
		if err != nil {
			t.Fatalf("read %s: %v", f, err)
		}
		for _, bad := range forbidden {
			if strings.Contains(string(data), bad) {
				t.Errorf("%s contains forbidden shell-out marker %q", f, bad)
			}
		}
	}
	if checked == 0 {
		t.Fatal("no production .go files were checked")
	}
}

// TestSubscriptionURLNotInjectable checks that neither the ntfy id nor the topic
// can escape its slot: the id stays exactly one `since` query parameter and the
// topic stays in the path.
func TestSubscriptionURLNotInjectable(t *testing.T) {
	ids := []string{
		"a&b", "a#b", "a?b", "a%b", "a=b", "a b", "a\nb", "a\rb",
		"a&since=evil", "a+b", "a;b", "a#frag&x=1", "%2F", "..", "ü",
	}
	for _, id := range ids {
		got, err := subscriptionURL("https://ntfy.sh", "mytopic", id)
		if err != nil {
			t.Fatalf("subscriptionURL(id=%q): %v", id, err)
		}
		u, err := url.Parse(got)
		if err != nil {
			t.Fatalf("url.Parse(%q): %v", got, err)
		}
		if u.Path != "/mytopic/json" {
			t.Errorf("id=%q: path = %q, want /mytopic/json", id, u.Path)
		}
		if u.Fragment != "" {
			t.Errorf("id=%q: fragment = %q, want empty", id, u.Fragment)
		}
		q := u.Query()
		if len(q) != 1 {
			t.Errorf("id=%q: query = %v, want exactly {since}", id, q)
		}
		if since := q.Get("since"); since != id {
			t.Errorf("id=%q: since = %q, want the exact id", id, since)
		}
	}
}

func TestSubscriptionURLTopicStaysInPath(t *testing.T) {
	cases := []struct{ topic, wantPath string }{
		{"mytopic", "/mytopic/json"},
		{"my/topic", "/my/topic/json"},
		{"a b", "/a b/json"},
		{"a?b", "/a?b/json"},
		{"a#b", "/a#b/json"},
		{"a&b=c", "/a&b=c/json"},
	}
	for _, c := range cases {
		got, err := subscriptionURL("https://ntfy.sh", c.topic, "")
		if err != nil {
			t.Fatalf("subscriptionURL(topic=%q): %v", c.topic, err)
		}
		u, err := url.Parse(got)
		if err != nil {
			t.Fatalf("url.Parse(%q): %v", got, err)
		}
		if u.Path != c.wantPath {
			t.Errorf("topic=%q: path = %q, want %q", c.topic, u.Path, c.wantPath)
		}
		if len(u.Query()) != 0 {
			t.Errorf("topic=%q: topic leaked into the query: %v", c.topic, u.Query())
		}
		if u.Fragment != "" {
			t.Errorf("topic=%q: topic leaked into the fragment: %q", c.topic, u.Fragment)
		}
	}
}

// TestStreamHTTPErrorBodyNotInjectable covers the hostile/misconfigured ntfy
// server: the HTTP error body flows into an error that run logs with %v. If the
// body is interpolated raw, a newline in it forges an extra stderr log line.
func TestStreamHTTPErrorBodyNotInjectable(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "boom\nopencode-ntfy-notifier: FORGED LOG LINE\n")
	}))
	defer server.Close()

	s := &ntfyStreamer{
		server: server.URL,
		topic:  "mytopic",
		client: server.Client(),
		logger: log.New(io.Discard, "", 0),
	}
	if _, err := s.stream(context.Background(), "", func(ntfyEvent) {}); err == nil {
		t.Fatal("expected an error for a 500 response")
	} else {
		var buf bytes.Buffer
		log.New(&buf, "opencode-ntfy-notifier: ", 0).Printf("ntfy stream ended (%v); reconnecting", err)
		if got := strings.Count(buf.String(), "\n"); got != 1 {
			t.Errorf("server-controlled error body produced %d log lines, want 1: %q", got, buf.String())
		}
	}
}

// TestFocusSessionLogNotInjectable captures the focus logger while focusing a
// workspace name full of control characters. With %q the only newline in the
// output is the logger's own terminator; anything else would let a title forge
// a log line.
func TestFocusSessionLogNotInjectable(t *testing.T) {
	payload := "evil\nsecond line\rreturn\ttab\"quote\\back\u2028sep"
	f := startFakeNiri(t, func(request json.RawMessage) any {
		if string(request) == `"Workspaces"` {
			return workspacesReply(payload)
		}
		return map[string]any{"Ok": "Handled"}
	})
	t.Setenv("NIRI_SOCKET", f.path)

	var buf bytes.Buffer
	logger := log.New(&buf, "test: ", 0)
	focusSession(newNiriFocuser(), logger, payload)

	out := buf.String()
	if !strings.HasSuffix(out, "\n") {
		t.Errorf("log output does not end in a newline: %q", out)
	}
	if got := strings.Count(out, "\n"); got != 1 {
		t.Errorf("log output has %d newlines, want 1 (forged log line?): %q", got, out)
	}
	if !strings.Contains(out, `focused workspace "`) {
		t.Errorf("log output missing the quoted session: %q", out)
	}
	if !strings.Contains(out, `evil\nsecond line`) {
		t.Errorf("newline in the session was not escaped: %q", out)
	}
	if strings.Contains(out, "second line\rreturn") {
		t.Errorf("carriage return in the session was not escaped: %q", out)
	}
}

// TestParseSessionAdversarial exercises the untrusted first-line parser. It must
// never panic and must truncate at the first newline (so a title can never smuggle
// a second line through).
func TestParseSessionAdversarial(t *testing.T) {
	huge := strings.Repeat("A", 1<<20)
	tests := []struct {
		name    string
		message string
		want    string
	}{
		{"empty", "", ""},
		{"empty title", "Session: \"\"\nHostname: h", ""},
		{"whitespace only title", "Session:     \nHostname: h", ""},
		{"missing prefix", "Hostname: h", ""},
		{"case sensitive prefix", "session: \"x\"", ""},
		{"embedded quotes kept", `Session: "a"b"` + "\nHostname: h", `a"b`},
		{"trailing spaces stripped", "Session: \"  x  \"", "x"},
		{"unquoted", "Session: x", "x"},
		{"newline truncates", "Session: \"a\nb\"", "a"},
		{"embedded nul", "Session: \"a\x00b\"", "a\x00b"},
		{"line separator", "Session: \"a\u2028b\"", "a\u2028b"},
		{"numeric", "Session: \"3\"", "3"},
		{"json structure injection", `Session: "x"}},{"Action":{"FocusWorkspace":{"reference":{"Name":"evil"` + "\nHostname: h", `x"}},{"Action":{"FocusWorkspace":{"reference":{"Name":"evil`},
		{"huge input", "Session: " + huge, huge},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := parseSession(tt.message); got != tt.want {
				t.Errorf("parseSession(%q) = %q, want %q", tt.message, got, tt.want)
			}
		})
	}
}

// TestNotifyPassesAttackerStringsAsSingleArguments checks the D-Bus sink: a
// summary/body with quotes, backslashes, and control characters is marshalled as
// one string argument and comes back unchanged. The daemon is a fake on a private
// bus; it does not advertise body-markup, matching the real pipeline where the
// body is plain text.
func TestNotifyPassesAttackerStringsAsSingleArguments(t *testing.T) {
	startPrivateSessionBus(t)
	daemon := startFakeNotificationDaemon(t)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	actions := make(chan string, 4)
	n, err := newNotifier(ctx, log.New(io.Discard, "", 0), func(s string) { actions <- s })
	if err != nil {
		t.Fatalf("newNotifier: %v", err)
	}
	defer n.Close()

	summary := "Agent \"Idle\" \\ a\tb\x1b[31mred"
	body := "Session: \"x\\\"}},&<>`$(); touch /tmp/nope\"\nHostname: h\u2028end"
	session := "ws\"'\\\ttab"

	if _, err := n.Notify(summary, body, "critical", session); err != nil {
		t.Fatalf("Notify: %v", err)
	}

	got := daemon.notifications()
	if len(got) != 1 {
		t.Fatalf("got %d notifications, want 1", len(got))
	}
	if got[0].summary != summary {
		t.Errorf("summary = %q, want %q", got[0].summary, summary)
	}
	if got[0].body != body {
		t.Errorf("body = %q, want %q", got[0].body, body)
	}
	hasDefault := false
	for i := 0; i+1 < len(got[0].actions); i += 2 {
		if got[0].actions[i] == "default" {
			hasDefault = true
		}
	}
	if !hasDefault {
		t.Errorf("actions = %v, want a %q action", got[0].actions, "default")
	}
}

// TestEndToEndJSONInjectionFocusesWholePayload runs the full pipeline for the
// structural JSON-injection payload: ntfy message -> parseSession -> desktop
// notification -> ActionInvoked click -> niri FocusWorkspace. niri must receive
// exactly one request whose Name is the whole payload.
func TestEndToEndJSONInjectionFocusesWholePayload(t *testing.T) {
	startPrivateSessionBus(t)
	startFakeNotificationDaemon(t)

	payload := `x"}},{"Action":{"FocusWorkspace":{"reference":{"Name":"evil`
	niri := startFakeNiri(t, func(request json.RawMessage) any {
		if string(request) == `"Workspaces"` {
			return workspacesReply(payload)
		}
		return map[string]any{"Ok": "Handled"}
	})
	t.Setenv("NIRI_SOCKET", niri.path)

	body := "Session: \"" + payload + "\"\nHostname: test"
	line, err := json.Marshal(map[string]any{
		"id":       "inj1",
		"time":     1,
		"event":    "message",
		"topic":    "t",
		"title":    "Agent Idle",
		"message":  body,
		"priority": 4,
	})
	if err != nil {
		t.Fatal(err)
	}
	server := startFakeNtfy(t, string(line))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	errc := make(chan error, 1)
	go func() {
		errc <- run(ctx, runConfig{configPath: "test", topic: "dummy", server: server.URL}, log.New(io.Discard, "", 0))
	}()

	deadline := time.Now().Add(10 * time.Second)
	for {
		if focus := focusRequests(niri.received()); len(focus) >= 1 {
			assertFocusRequest(t, focus[0], payload)
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("timed out waiting for niri FocusWorkspace")
		}
		time.Sleep(10 * time.Millisecond)
	}

	cancel()
	select {
	case err := <-errc:
		if err != nil {
			t.Fatalf("run returned %v", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("run did not return after cancellation")
	}

	if focus := focusRequests(niri.received()); len(focus) != 1 {
		t.Errorf("got %d focus requests, want exactly 1 (newline split?)", len(focus))
	}
}
