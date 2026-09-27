package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/godbus/dbus/v5"
)

// startPrivateSessionBus launches a throwaway session bus and points
// DBUS_SESSION_BUS_ADDRESS at it. It skips the test if dbus-daemon is missing.
func startPrivateSessionBus(t *testing.T) string {
	t.Helper()
	bin, err := exec.LookPath("dbus-daemon")
	if err != nil {
		t.Skip("dbus-daemon not available; skipping D-Bus integration test")
	}

	cmd := exec.Command(bin, "--session", "--nofork", "--print-address")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		t.Fatal(err)
	}
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Start(); err != nil {
		t.Fatalf("start dbus-daemon: %v", err)
	}
	t.Cleanup(func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	})

	reader := bufio.NewReader(stdout)
	addr, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("read dbus-daemon address: %v (stderr: %s)", err, stderr.String())
	}
	go io.Copy(io.Discard, reader) // keep the pipe drained

	addr = strings.TrimSpace(addr)
	if addr == "" {
		t.Fatalf("dbus-daemon returned an empty address (stderr: %s)", stderr.String())
	}
	t.Setenv("DBUS_SESSION_BUS_ADDRESS", addr)
	return addr
}

type capturedNotification struct {
	summary string
	body    string
	actions []string
}

// fakeNotificationDaemon owns org.freedesktop.Notifications on a private bus
// and simulates a user clicking the notification body by emitting
// ActionInvoked("default") shortly after each Notify call.
type fakeNotificationDaemon struct {
	conn *dbus.Conn

	mu   sync.Mutex
	got  []capturedNotification
	next uint32
}

func startFakeNotificationDaemon(t *testing.T) *fakeNotificationDaemon {
	t.Helper()
	conn, err := dbus.SessionBusPrivate()
	if err != nil {
		t.Fatalf("connect to private session bus: %v", err)
	}
	if err := conn.Auth(nil); err != nil {
		t.Fatalf("authenticate: %v", err)
	}
	if err := conn.Hello(); err != nil {
		t.Fatalf("hello: %v", err)
	}
	t.Cleanup(func() { conn.Close() })

	reply, err := conn.RequestName(notificationsDest, dbus.NameFlagDoNotQueue)
	if err != nil {
		t.Fatalf("request %s: %v", notificationsDest, err)
	}
	if reply != dbus.RequestNameReplyPrimaryOwner {
		t.Fatalf("request %s = %v, want primary owner", notificationsDest, reply)
	}

	d := &fakeNotificationDaemon{conn: conn}
	if err := conn.Export(d, notificationsPath, notificationsIface); err != nil {
		t.Fatalf("export notification daemon: %v", err)
	}
	return d
}

// Notify implements org.freedesktop.Notifications.Notify (susssasa{sv}i -> u).
func (d *fakeNotificationDaemon) Notify(appName string, replacesID uint32, appIcon, summary, body string, actions []string, hints map[string]dbus.Variant, expireTimeout int32) (uint32, *dbus.Error) {
	d.mu.Lock()
	d.next++
	id := d.next
	d.got = append(d.got, capturedNotification{
		summary: summary,
		body:    body,
		actions: append([]string(nil), actions...),
	})
	d.mu.Unlock()

	// Let the client finish recording the id -> session mapping before the
	// signal lands, mimicking a user clicking the notification body.
	go func() {
		time.Sleep(100 * time.Millisecond)
		_ = d.conn.Emit(notificationsPath, actionInvoked, id, "default")
	}()
	return id, nil
}

func (d *fakeNotificationDaemon) notifications() []capturedNotification {
	d.mu.Lock()
	defer d.mu.Unlock()
	return append([]capturedNotification(nil), d.got...)
}

// fakeNiriFocus is a one-request-per-connection fake of the niri IPC socket
// that reports named workspaces and records FocusWorkspace targets.
type fakeNiriFocus struct {
	path  string
	focus chan string
}

func startFakeNiriFocus(t *testing.T, workspaceNames ...string) *fakeNiriFocus {
	t.Helper()
	path := filepath.Join(t.TempDir(), "niri.sock")
	ln, err := net.Listen("unix", path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ln.Close() })

	f := &fakeNiriFocus{path: path, focus: make(chan string, 8)}
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			go func(conn net.Conn) {
				defer conn.Close()
				line, err := bufio.NewReader(conn).ReadBytes('\n')
				if err != nil {
					return
				}

				var reply any
				if strings.TrimSpace(string(line)) == `"Workspaces"` {
					workspaces := make([]any, 0, len(workspaceNames))
					for i, name := range workspaceNames {
						workspaces = append(workspaces, map[string]any{
							"id":               i + 1,
							"idx":              i + 1,
							"name":             name,
							"output":           "eDP-1",
							"is_urgent":        false,
							"is_active":        i == 0,
							"is_focused":       i == 0,
							"active_window_id": i + 1,
						})
					}
					reply = map[string]any{"Ok": map[string]any{"Workspaces": workspaces}}
				} else {
					var request struct {
						Action struct {
							FocusWorkspace struct {
								Reference struct {
									Name *string `json:"Name"`
								} `json:"reference"`
							} `json:"FocusWorkspace"`
						} `json:"Action"`
					}
					if err := json.Unmarshal(line, &request); err == nil && request.Action.FocusWorkspace.Reference.Name != nil {
						f.focus <- *request.Action.FocusWorkspace.Reference.Name
					}
					reply = map[string]any{"Ok": "Handled"}
				}

				out, _ := json.Marshal(reply)
				_, _ = conn.Write(append(out, '\n'))
			}(conn)
		}
	}()
	return f
}

// startFakeNtfy serves the given NDJSON lines and then holds the connection
// open until the test finishes, so the streamer neither reconnects nor backs
// off during the test.
func startFakeNtfy(t *testing.T, lines ...string) *httptest.Server {
	t.Helper()
	done := make(chan struct{})
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/dummy/json" {
			t.Errorf("ntfy request path = %q, want /dummy/json", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/x-ndjson")
		flusher, _ := w.(http.Flusher)
		for _, line := range lines {
			fmt.Fprintln(w, line)
			if flusher != nil {
				flusher.Flush()
			}
		}
		select {
		case <-done:
		case <-r.Context().Done():
		}
	}))
	t.Cleanup(func() {
		close(done)
		server.Close()
	})
	return server
}

// TestEndToEndNotificationToNiriFocus drives the whole pipeline in-process:
// ntfy message -> parse session -> desktop notification -> ActionInvoked click
// -> niri FocusWorkspace.
func TestEndToEndNotificationToNiriFocus(t *testing.T) {
	startPrivateSessionBus(t)
	daemon := startFakeNotificationDaemon(t)

	// The workspace list must already contain the session; niri silently
	// no-ops on an unknown name.
	niri := startFakeNiriFocus(t, "__PRESENT__", "my-session")
	t.Setenv("NIRI_SOCKET", niri.path)

	server := startFakeNtfy(t, `{"id":"abc","time":1,"event":"message","topic":"t","title":"Agent Idle","message":"Session: \"my-session\"\nHostname: test","priority":4,"tags":["hourglass_done"]}`)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	errc := make(chan error, 1)
	go func() {
		errc <- run(ctx, runConfig{configPath: "test", topic: "dummy", server: server.URL}, log.New(io.Discard, "", 0))
	}()

	select {
	case name := <-niri.focus:
		if name != "my-session" {
			t.Fatalf("niri focused %q, want my-session", name)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("timed out waiting for niri FocusWorkspace")
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

	got := daemon.notifications()
	if len(got) != 1 {
		t.Fatalf("got %d notifications, want 1", len(got))
	}
	n := got[0]
	if n.summary != "Agent Idle" {
		t.Errorf("notification summary = %q, want %q", n.summary, "Agent Idle")
	}
	if !strings.Contains(n.body, "my-session") {
		t.Errorf("notification body = %q, want it to contain %q", n.body, "my-session")
	}
	hasDefault := false
	for i := 0; i+1 < len(n.actions); i += 2 {
		if n.actions[i] == "default" {
			hasDefault = true
		}
	}
	if !hasDefault {
		t.Errorf("notification actions = %v, want a %q action", n.actions, "default")
	}
}

// TestRunReconnectsWithSince covers the reconnect loop: after the first stream
// delivers a message and ends, the next connection must resume from that id.
func TestRunReconnectsWithSince(t *testing.T) {
	startPrivateSessionBus(t)

	var mu sync.Mutex
	first := true
	second := make(chan string, 1)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		isFirst := first
		first = false
		mu.Unlock()

		w.Header().Set("Content-Type", "application/x-ndjson")
		if isFirst {
			fmt.Fprintln(w, `{"id":"first","event":"message","title":"Agent Idle","message":"Session: \"s\"\nHostname: h","priority":4}`)
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			}
			return // closing the stream triggers a reconnect
		}
		select {
		case second <- r.URL.Query().Get("since"):
		default:
		}
		<-r.Context().Done()
	}))
	defer server.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	errc := make(chan error, 1)
	go func() {
		// No notification daemon is needed: Notify fails harmlessly and the
		// loop keeps streaming.
		errc <- run(ctx, runConfig{configPath: "test", topic: "dummy", server: server.URL}, log.New(io.Discard, "", 0))
	}()

	select {
	case got := <-second:
		if got != "first" {
			t.Fatalf("second connection used since=%q, want %q", got, "first")
		}
	case <-time.After(10 * time.Second):
		t.Fatal("timed out waiting for the streamer to reconnect")
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
}

// TestLiveNtfyRoundTrip exercises the real ntfy.sh protocol. It is opt-in so
// normal test runs stay offline and side-effect free.
func TestLiveNtfyRoundTrip(t *testing.T) {
	if os.Getenv("NTFY_LIVE_TEST") != "1" {
		t.Skip("set NTFY_LIVE_TEST=1 to run against ntfy.sh")
	}

	const base = "https://ntfy.sh"
	topic := fmt.Sprintf("opencode-ntfy-test-%d-%d", time.Now().UnixNano(), rand.Int63())
	t.Logf("live topic: %s/%s", base, topic)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	received := make(chan string, 1)
	streamer := &ntfyStreamer{
		server: base,
		topic:  topic,
		client: &http.Client{},
		logger: log.New(io.Discard, "", 0),
	}
	go func() {
		_, _ = streamer.stream(ctx, "", func(ev ntfyEvent) {
			if session := parseSession(ev.Message); session != "" {
				select {
				case received <- session:
				default:
				}
			}
		})
	}()

	// Give the subscription a moment to establish before publishing. ntfy also
	// caches messages, so a slightly early publish is still delivered.
	time.Sleep(time.Second)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, base+"/"+topic,
		strings.NewReader("Session: \"live-session\"\nHostname: test"))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Title", "Agent Idle")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("publish to ntfy: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("publish status = %s", resp.Status)
	}

	select {
	case session := <-received:
		if session != "live-session" {
			t.Fatalf("parseSession = %q, want %q", session, "live-session")
		}
	case <-time.After(15 * time.Second):
		t.Fatal("timed out waiting for the live ntfy message")
	}
}
