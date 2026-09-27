package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	logger := log.New(os.Stderr, "opencode-ntfy-notifier: ", log.LstdFlags)

	configPath := flag.String("config", defaultConfigPath(), "path to notification-ntfy.json")
	topicFlag := flag.String("topic", "", "ntfy topic (overrides config and $OPENCODE_NTFY_TOPIC)")
	serverFlag := flag.String("server", "", "ntfy server URL (overrides config and $OPENCODE_NTFY_SERVER)")
	tokenFlag := flag.String("token", "", "ntfy bearer token (overrides config and $OPENCODE_NTFY_TOKEN)")
	flag.Parse()

	cfg, err := loadConfig(*configPath)
	if err != nil {
		logger.Fatalf("%v", err)
	}
	if !cfg.enabled() {
		logger.Printf("disabled in %s; exiting", *configPath)
		return
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	runCfg := runConfig{
		configPath: *configPath,
		topic:      firstNonEmpty(*topicFlag, os.Getenv("OPENCODE_NTFY_TOPIC"), cfg.Backend.Topic),
		server:     firstNonEmpty(*serverFlag, os.Getenv("OPENCODE_NTFY_SERVER"), cfg.Backend.Server, "https://ntfy.sh"),
		token:      firstNonEmpty(*tokenFlag, os.Getenv("OPENCODE_NTFY_TOKEN"), cfg.Backend.Token),
	}
	if err := run(ctx, runCfg, logger); err != nil {
		logger.Fatalf("%v", err)
	}
}

// runConfig is the fully resolved configuration for run: flag > environment >
// config-file precedence is applied by main before run is called.
type runConfig struct {
	configPath string
	topic      string
	server     string
	token      string
}

// run subscribes to the ntfy stream and drives the notification/niri-focus
// pipeline until ctx is cancelled. It is extracted from main so tests can run
// the whole loop in-process against fakes.
func run(ctx context.Context, cfg runConfig, logger *log.Logger) error {
	if cfg.topic == "" {
		return fmt.Errorf("no ntfy topic configured: set backend.topic in %s, or pass -topic / $OPENCODE_NTFY_TOPIC", cfg.configPath)
	}

	niri := newNiriFocuser()
	notifier, err := newNotifier(ctx, logger, func(session string) {
		focusSession(niri, logger, session)
	})
	if err != nil {
		return fmt.Errorf("connect to session D-Bus: %w", err)
	}
	defer notifier.Close()

	streamer := &ntfyStreamer{
		server: cfg.server,
		topic:  cfg.topic,
		token:  cfg.token,
		client: &http.Client{},
		logger: logger,
	}
	logger.Printf("subscribing to %s/%s/json", cfg.server, cfg.topic)

	backoff := time.Second
	var since string
	for ctx.Err() == nil {
		start := time.Now()
		last, err := streamer.stream(ctx, since, func(ev ntfyEvent) {
			session := parseSession(ev.Message)
			summary := ev.Title
			if summary == "" {
				summary = "opencode"
			}
			id, err := notifier.Notify(summary, ev.Message, urgency(ev.Priority), session)
			if err != nil {
				logger.Printf("notify: %v", err)
				return
			}
			logger.Printf("notified id=%d session=%q", id, session)
		})
		if last != "" {
			since = last
		}
		if ctx.Err() != nil {
			break
		}

		// A stream that lasted a while was healthy; don't keep growing the delay.
		if time.Since(start) > 30*time.Second {
			backoff = time.Second
		}
		logger.Printf("ntfy stream ended (%v); reconnecting in %s (since=%q)", err, backoff, since)
		select {
		case <-ctx.Done():
		case <-time.After(backoff):
		}
		if backoff < 30*time.Second {
			backoff *= 2
		}
	}
	logger.Printf("shutting down")
	return nil
}

// focusSession focuses the niri workspace matching session and logs the
// outcome. session is attacker-controlled, so it is only ever logged with %q,
// which escapes newlines and control characters and keeps a crafted title from
// forging an extra log line.
func focusSession(niri *niriFocuser, logger *log.Logger, session string) {
	if session == "" {
		logger.Printf("notification action ignored: empty session name")
		return
	}
	if err := niri.focusWorkspace(session); err != nil {
		logger.Printf("focus workspace: %v", err)
		return
	}
	logger.Printf("focused workspace %q", session)
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}
