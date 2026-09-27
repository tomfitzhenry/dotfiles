package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"strings"
	"time"
)

const niriSocketEnv = "NIRI_SOCKET"

// niriFocuser focuses niri workspaces by speaking niri's IPC protocol
// directly over $NIRI_SOCKET. It deliberately does not shell out to
// `niri msg`, whose CLI coerces a numeric-looking argument into a workspace
// *index* (niri-ipc/src/lib.rs, `FromStr for WorkspaceReferenceArg`:
// `s.parse::<i32>()` -> `Index`). Sending the explicit `Name` variant instead
// means a session title like "1" is always treated as a name.
type niriFocuser struct{}

type niriWorkspace struct {
	Name *string `json:"name"`
}

func newNiriFocuser() *niriFocuser { return &niriFocuser{} }

// niriReply is the JSON envelope for a niri IPC reply: `Reply = Result<Response, String>`
// (niri-ipc/src/lib.rs), i.e. `{"Ok": <response>}` or `{"Err": "<message>"}`.
type niriReply struct {
	Ok  json.RawMessage `json:"Ok"`
	Err *string         `json:"Err"`
}

func (r niriReply) err() error {
	if r.Err != nil {
		return fmt.Errorf("niri: %s", *r.Err)
	}
	if len(r.Ok) == 0 {
		return fmt.Errorf("niri: reply has neither Ok nor Err")
	}
	return nil
}

// send writes one request line and reads one reply line, mirroring
// niri-ipc/src/socket.rs::Socket::send (one request per connection).
func (n *niriFocuser) send(request any) (json.RawMessage, error) {
	path := os.Getenv(niriSocketEnv)
	if path == "" {
		return nil, fmt.Errorf("%s is not set; are you running within niri?", niriSocketEnv)
	}

	conn, err := net.DialTimeout("unix", path, 5*time.Second)
	if err != nil {
		return nil, fmt.Errorf("connect to niri socket %s: %w", path, err)
	}
	defer conn.Close()
	_ = conn.SetDeadline(time.Now().Add(5 * time.Second))

	payload, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}
	payload = append(payload, '\n')
	if _, err := conn.Write(payload); err != nil {
		return nil, fmt.Errorf("write niri request: %w", err)
	}

	line, err := bufio.NewReader(conn).ReadBytes('\n')
	if err != nil && len(line) == 0 {
		return nil, fmt.Errorf("read niri reply: %w", err)
	}
	var reply niriReply
	if err := json.Unmarshal(line, &reply); err != nil {
		return nil, fmt.Errorf("parse niri reply: %w", err)
	}
	if err := reply.err(); err != nil {
		return nil, err
	}
	return reply.Ok, nil
}

// workspaceNames lists the names of all current workspaces. Unnamed
// workspaces (`"name": null`) are skipped.
func (n *niriFocuser) workspaceNames() ([]string, error) {
	ok, err := n.send("Workspaces")
	if err != nil {
		return nil, err
	}
	var resp struct {
		Workspaces []niriWorkspace `json:"Workspaces"`
	}
	if err := json.Unmarshal(ok, &resp); err != nil {
		return nil, fmt.Errorf("parse niri workspaces: %w", err)
	}
	names := make([]string, 0, len(resp.Workspaces))
	for _, w := range resp.Workspaces {
		if w.Name != nil {
			names = append(names, *w.Name)
		}
	}
	return names, nil
}

// focusWorkspace focuses the workspace named name. It first checks the
// workspace list because niri silently does nothing (yet still replies
// `Handled`) when no workspace has the name: find_output_and_workspace_index
// (niri/src/niri.rs) returns None for `WorkspaceReference::Name` when
// find_workspace_by_name (niri/src/layout/mod.rs, case-insensitive) misses, and
// the Action::FocusWorkspace arm (niri/src/input/mod.rs) is then a no-op.
func (n *niriFocuser) focusWorkspace(name string) error {
	if name == "" {
		return fmt.Errorf("empty workspace name")
	}

	names, err := n.workspaceNames()
	if err != nil {
		return fmt.Errorf("list niri workspaces: %w", err)
	}
	if !containsFold(names, name) {
		return fmt.Errorf("no niri workspace named %q (existing: %s)", name, strings.Join(names, ", "))
	}

	if _, err := n.send(focusWorkspaceRequest(name)); err != nil {
		return fmt.Errorf("focus workspace %q: %w", name, err)
	}
	return nil
}

// focusWorkspaceRequest builds the IPC payload for focusing a workspace by
// name. The name is carried as a JSON string value, so encoding/json escapes
// quotes, newlines, and control characters; a crafted name cannot add keys or
// break out into a second request line.
func focusWorkspaceRequest(name string) map[string]any {
	return map[string]any{
		"Action": map[string]any{
			"FocusWorkspace": map[string]any{
				"reference": map[string]any{"Name": name},
			},
		},
	}
}

func containsFold(names []string, want string) bool {
	for _, name := range names {
		if strings.EqualFold(name, want) {
			return true
		}
	}
	return false
}
