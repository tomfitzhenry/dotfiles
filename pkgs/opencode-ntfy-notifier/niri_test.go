package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"net"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

// fakeNiri is a one-request-per-connection fake of the niri IPC socket.
type fakeNiri struct {
	path string

	mu       sync.Mutex
	requests []json.RawMessage
}

func startFakeNiri(t *testing.T, serve func(request json.RawMessage) any) *fakeNiri {
	t.Helper()
	path := filepath.Join(t.TempDir(), "niri.sock")
	ln, err := net.Listen("unix", path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ln.Close() })

	f := &fakeNiri{path: path}
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
				request := json.RawMessage(bytes.TrimRight(line, "\r\n"))

				f.mu.Lock()
				f.requests = append(f.requests, request)
				f.mu.Unlock()

				reply, err := json.Marshal(serve(request))
				if err != nil {
					return
				}
				conn.Write(append(reply, '\n'))
			}(conn)
		}
	}()
	return f
}

func (f *fakeNiri) received() []json.RawMessage {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]json.RawMessage(nil), f.requests...)
}

func workspacesReply(names ...any) any {
	workspaces := make([]any, 0, len(names))
	for i, name := range names {
		workspaces = append(workspaces, map[string]any{
			"id":               i + 1,
			"idx":              i + 1,
			"name":             name,
			"output":           "eDP-1",
			"is_urgent":        false,
			"is_active":        i == 0,
			"is_focused":       i == 0,
			"active_window_id": nil,
		})
	}
	return map[string]any{"Ok": map[string]any{"Workspaces": workspaces}}
}

func TestWorkspaceNamesParsesNullName(t *testing.T) {
	f := startFakeNiri(t, func(json.RawMessage) any {
		return workspacesReply("web", nil, "docs")
	})
	t.Setenv("NIRI_SOCKET", f.path)

	names, err := newNiriFocuser().workspaceNames()
	if err != nil {
		t.Fatal(err)
	}
	if got, want := strings.Join(names, ","), "web,docs"; got != want {
		t.Errorf("names = %q, want %q", got, want)
	}

	requests := f.received()
	if len(requests) != 1 {
		t.Fatalf("got %d requests, want 1", len(requests))
	}
	if string(requests[0]) != `"Workspaces"` {
		t.Errorf("request = %s, want \"Workspaces\"", requests[0])
	}
}

func TestFocusWorkspaceUsesExplicitNameVariant(t *testing.T) {
	f := startFakeNiri(t, func(request json.RawMessage) any {
		if string(request) == `"Workspaces"` {
			return workspacesReply("alpha", "Beta", "my session, (x)")
		}
		return map[string]any{"Ok": "Handled"}
	})
	t.Setenv("NIRI_SOCKET", f.path)

	if err := newNiriFocuser().focusWorkspace("beta"); err != nil {
		t.Fatalf("focusWorkspace: %v", err)
	}
	if err := newNiriFocuser().focusWorkspace("my session, (x)"); err != nil {
		t.Fatalf("focusWorkspace: %v", err)
	}

	focusRequests := 0
	for _, request := range f.received() {
		if string(request) == `"Workspaces"` {
			continue
		}
		var decoded map[string]any
		if err := json.Unmarshal(request, &decoded); err != nil {
			t.Fatalf("decode %s: %v", request, err)
		}
		action, ok := decoded["Action"].(map[string]any)
		if !ok {
			t.Fatalf("expected an Action request, got %s", request)
		}
		focusRequests++
		fw, ok := action["FocusWorkspace"].(map[string]any)
		if !ok {
			t.Fatalf("Action is not FocusWorkspace: %s", request)
		}
		ref, ok := fw["reference"].(map[string]any)
		if !ok {
			t.Fatalf("missing reference: %s", request)
		}
		if _, bad := ref["Index"]; bad {
			t.Errorf("reference must not use Index: %s", request)
		}
		if _, bad := ref["Id"]; bad {
			t.Errorf("reference must not use Id: %s", request)
		}
		if _, ok := ref["Name"]; !ok {
			t.Errorf("reference must use Name: %s", request)
		}
	}
	if focusRequests != 2 {
		t.Errorf("got %d FocusWorkspace requests, want 2", focusRequests)
	}
}

func TestFocusWorkspaceUnknownNameSkipsRequest(t *testing.T) {
	f := startFakeNiri(t, func(request json.RawMessage) any {
		return workspacesReply("alpha", "Beta")
	})
	t.Setenv("NIRI_SOCKET", f.path)

	err := newNiriFocuser().focusWorkspace("gamma")
	if err == nil {
		t.Fatal("expected error for unknown workspace")
	}
	if !strings.Contains(err.Error(), "gamma") {
		t.Errorf("error should name the workspace: %v", err)
	}

	requests := f.received()
	if len(requests) != 1 || string(requests[0]) != `"Workspaces"` {
		t.Errorf("expected only a Workspaces request, got %v", requests)
	}
}

func TestFocusWorkspaceNumericNameIsNotAnIndex(t *testing.T) {
	f := startFakeNiri(t, func(request json.RawMessage) any {
		return workspacesReply("alpha")
	})
	t.Setenv("NIRI_SOCKET", f.path)

	if err := newNiriFocuser().focusWorkspace("1"); err == nil {
		t.Error("expected error: no workspace named 1")
	}
	requests := f.received()
	if len(requests) != 1 || string(requests[0]) != `"Workspaces"` {
		t.Errorf("numeric name must not be forwarded as an index; requests = %v", requests)
	}
}

func TestFocusWorkspaceEmpty(t *testing.T) {
	if err := newNiriFocuser().focusWorkspace(""); err == nil {
		t.Error("expected error for empty name")
	}
}

func TestNiriSocketUnset(t *testing.T) {
	t.Setenv("NIRI_SOCKET", "")
	if _, err := newNiriFocuser().workspaceNames(); err == nil {
		t.Fatal("expected error when NIRI_SOCKET is unset")
	} else if !strings.Contains(err.Error(), "NIRI_SOCKET") {
		t.Errorf("error should mention NIRI_SOCKET: %v", err)
	}
}

func TestNiriErrorReply(t *testing.T) {
	f := startFakeNiri(t, func(json.RawMessage) any {
		return map[string]any{"Err": "some failure"}
	})
	t.Setenv("NIRI_SOCKET", f.path)

	if _, err := newNiriFocuser().workspaceNames(); err == nil {
		t.Fatal("expected error for Err reply")
	} else if !strings.Contains(err.Error(), "some failure") {
		t.Errorf("error should surface niri's message: %v", err)
	}
}
