package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// Config mirrors ~/.config/opencode/notification-ntfy.json. The file is
// hand-written rather than Nix-managed because the topic and token are
// secrets, so it must never be required for the program to start.
type Config struct {
	// Enabled is a pointer so that an absent field defaults to enabled, while
	// an explicit `"enabled": false` disables the notifier.
	Enabled *bool   `json:"enabled"`
	Backend Backend `json:"backend"`
}

type Backend struct {
	Topic    string `json:"topic"`
	Server   string `json:"server"`
	Priority string `json:"priority"`
	Token    string `json:"token"`
}

// defaultConfigPath follows XDG_CONFIG_HOME, falling back to ~/.config.
func defaultConfigPath() string {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		base = filepath.Join(home, ".config")
	}
	return filepath.Join(base, "opencode", "notification-ntfy.json")
}

// loadConfig reads path. A missing file is not an error; it yields a zero
// Config so topic and server can come from flags or the environment instead.
func loadConfig(path string) (Config, error) {
	var cfg Config
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return cfg, nil
	}
	if err != nil {
		return cfg, fmt.Errorf("read config %s: %w", path, err)
	}
	if err := json.Unmarshal(data, &cfg); err != nil {
		return cfg, fmt.Errorf("parse config %s: %w", path, err)
	}
	return cfg, nil
}

func (c Config) enabled() bool { return c.Enabled == nil || *c.Enabled }
