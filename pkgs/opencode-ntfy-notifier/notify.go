package main

import (
	"context"
	"fmt"
	"log"
	"sync"

	"github.com/godbus/dbus/v5"
)

const (
	notificationsDest  = "org.freedesktop.Notifications"
	notificationsPath  = dbus.ObjectPath("/org/freedesktop/Notifications")
	notificationsIface = "org.freedesktop.Notifications"
	actionInvoked      = notificationsIface + ".ActionInvoked"
	notificationClosed = notificationsIface + ".NotificationClosed"
)

// Notifier speaks org.freedesktop.Notifications directly over the session bus
// (no libnotify runtime dependency). It keeps the mapping from notification id
// to session name so that a later ActionInvoked("default") signal can focus the
// matching niri workspace.
type Notifier struct {
	conn     *dbus.Conn
	appName  string
	logger   *log.Logger
	onAction func(session string)

	mu       sync.Mutex
	sessions map[uint32]string
}

// sessionBus returns a private connection so Close doesn't tear down godbus's
// shared session bus for other goroutines.
func sessionBus() (*dbus.Conn, error) {
	conn, err := dbus.SessionBusPrivate()
	if err != nil {
		return nil, err
	}
	if err := conn.Auth(nil); err != nil {
		conn.Close()
		return nil, err
	}
	if err := conn.Hello(); err != nil {
		conn.Close()
		return nil, err
	}
	return conn, nil
}

func newNotifier(ctx context.Context, logger *log.Logger, onAction func(session string)) (*Notifier, error) {
	conn, err := sessionBus()
	if err != nil {
		return nil, err
	}
	n := &Notifier{
		conn:     conn,
		appName:  "opencode",
		logger:   logger,
		onAction: onAction,
		sessions: make(map[uint32]string),
	}
	if err := conn.AddMatchSignal(dbus.WithMatchInterface(notificationsIface)); err != nil {
		conn.Close()
		return nil, fmt.Errorf("subscribe to %s signals: %w", notificationsIface, err)
	}
	signals := make(chan *dbus.Signal, 32)
	conn.Signal(signals)
	go n.handleSignals(ctx, signals)
	return n, nil
}

// Notify posts a notification with a clickable `default` action (noctalia
// invokes it when the body is clicked) and remembers session under its id.
func (n *Notifier) Notify(summary, body, urgency, session string) (uint32, error) {
	actions := []string{"default", "Open workspace"}
	hints := map[string]dbus.Variant{
		"urgency":       dbus.MakeVariant(urgencyByte(urgency)),
		"desktop-entry": dbus.MakeVariant(n.appName),
	}
	obj := n.conn.Object(notificationsDest, notificationsPath)
	call := obj.Call(notificationsIface+".Notify", 0,
		n.appName, uint32(0), "", summary, body, actions, hints, int32(-1))
	if call.Err != nil {
		return 0, call.Err
	}
	var id uint32
	if err := call.Store(&id); err != nil {
		return 0, err
	}

	n.mu.Lock()
	n.sessions[id] = session
	n.mu.Unlock()
	return id, nil
}

func (n *Notifier) handleSignals(ctx context.Context, signals <-chan *dbus.Signal) {
	for {
		select {
		case <-ctx.Done():
			return
		case sig, ok := <-signals:
			if !ok {
				return
			}
			n.handleSignal(sig)
		}
	}
}

func (n *Notifier) handleSignal(sig *dbus.Signal) {
	if sig.Name != actionInvoked && sig.Name != notificationClosed {
		return
	}
	if len(sig.Body) < 1 {
		return
	}
	id, ok := sig.Body[0].(uint32)
	if !ok {
		return
	}

	switch sig.Name {
	case actionInvoked:
		if len(sig.Body) < 2 {
			return
		}
		key, _ := sig.Body[1].(string)
		if key != "default" {
			return
		}
		n.mu.Lock()
		session := n.sessions[id]
		delete(n.sessions, id)
		n.mu.Unlock()
		if session == "" {
			n.logger.Printf("notification %d action: no session name; ignoring", id)
			return
		}
		n.onAction(session)
	case notificationClosed:
		n.mu.Lock()
		delete(n.sessions, id)
		n.mu.Unlock()
	}
}

func (n *Notifier) Close() error {
	n.conn.RemoveMatchSignal(dbus.WithMatchInterface(notificationsIface))
	return n.conn.Close()
}

func urgencyByte(urgency string) byte {
	switch urgency {
	case "low":
		return 0
	case "critical":
		return 2
	default:
		return 1
	}
}
