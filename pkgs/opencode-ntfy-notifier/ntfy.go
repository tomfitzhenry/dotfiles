package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
)

// ntfyEvent is one line of the ntfy.sh JSON stream. Only `message` events are
// actionable; the stream also interleaves open/keepalive/message_delete/etc.
type ntfyEvent struct {
	ID       string `json:"id"`
	Time     int64  `json:"time"`
	Event    string `json:"event"`
	Topic    string `json:"topic"`
	Title    string `json:"title"`
	Message  string `json:"message"`
	Priority int    `json:"priority"`
}

// parseSession extracts the session title from a notification message:
//
//	Session: "<title>"
//	Hostname: <host>
//
// The title is not a separate field. It may be empty, contain spaces or
// punctuation, or be absent entirely (for example if the first line is a
// different key). Anything after the first line is ignored.
func parseSession(message string) string {
	line := message
	if i := strings.IndexByte(message, '\n'); i >= 0 {
		line = message[:i]
	}
	line = strings.TrimSpace(line)
	rest, ok := strings.CutPrefix(line, "Session:")
	if !ok {
		return ""
	}
	rest = strings.TrimSpace(rest)
	rest = strings.Trim(rest, `"`)
	return strings.TrimSpace(rest)
}

// urgency maps an ntfy priority (1..5) to an xdg notification urgency.
func urgency(priority int) string {
	switch {
	case priority <= 2:
		return "low"
	case priority == 3:
		return "normal"
	default:
		return "critical"
	}
}

// subscriptionURL builds {server}/{topic}/json, resuming from a message id via
// ?since= so that a reconnect doesn't drop messages delivered in the meantime.
func subscriptionURL(server, topic, since string) (string, error) {
	u, err := url.Parse(strings.TrimRight(server, "/"))
	if err != nil {
		return "", fmt.Errorf("parse server URL %q: %w", server, err)
	}
	if u.Host == "" {
		return "", fmt.Errorf("server URL %q has no host", server)
	}
	u.Path = strings.TrimRight(u.Path, "/") + "/" + topic + "/json"
	if since != "" {
		q := u.Query()
		q.Set("since", since)
		u.RawQuery = q.Encode()
	}
	return u.String(), nil
}

// ntfyStreamer consumes the streaming NDJSON endpoint. `stream` returns the
// last seen message id so the caller can persist it across reconnects.
type ntfyStreamer struct {
	server string
	topic  string
	token  string
	client *http.Client
	logger *log.Logger
}

// stream connects and invokes handle for every `message` event until the
// connection ends or ctx is cancelled. Both a clean EOF and a network error are
// returned as err so the caller can back off and reconnect.
func (s *ntfyStreamer) stream(ctx context.Context, since string, handle func(ntfyEvent)) (string, error) {
	endpoint, err := subscriptionURL(s.server, s.topic, since)
	if err != nil {
		return since, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return since, err
	}
	if s.token != "" {
		req.Header.Set("Authorization", "Bearer "+s.token)
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return since, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		// %q: the body is controlled by the (possibly hostile) ntfy server and
		// is logged by the caller, so escape it to keep it on one log line.
		return since, fmt.Errorf("ntfy %q: %q", resp.Status, strings.TrimSpace(string(body)))
	}

	last := since
	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)
	for scanner.Scan() {
		line := scanner.Bytes()
		if len(line) == 0 {
			continue
		}
		var ev ntfyEvent
		if err := json.Unmarshal(line, &ev); err != nil {
			s.logger.Printf("ntfy: skipping malformed line: %v", err)
			continue
		}
		if ev.ID != "" {
			last = ev.ID
		}
		if ev.Event != "message" {
			continue
		}
		handle(ev)
	}
	if err := scanner.Err(); err != nil {
		return last, err
	}
	return last, io.EOF
}
