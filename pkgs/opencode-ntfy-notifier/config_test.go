package main

import (
	"os"
	"path/filepath"
	"testing"
)

func writeConfig(t *testing.T, contents string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "notification-ntfy.json")
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestLoadConfig(t *testing.T) {
	path := writeConfig(t, `{
		"enabled": true,
		"backend": {
			"topic": "test-topic",
			"server": "https://ntfy.sh",
			"priority": "high",
			"token": "tk_secret"
		}
	}`)

	cfg, err := loadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if !cfg.enabled() {
		t.Error("expected enabled")
	}
	if cfg.Backend.Topic != "test-topic" {
		t.Errorf("topic = %q", cfg.Backend.Topic)
	}
	if cfg.Backend.Server != "https://ntfy.sh" {
		t.Errorf("server = %q", cfg.Backend.Server)
	}
	if cfg.Backend.Token != "tk_secret" {
		t.Errorf("token = %q", cfg.Backend.Token)
	}
}

func TestLoadConfigEnabledDefaultsTrue(t *testing.T) {
	cfg, err := loadConfig(writeConfig(t, `{"backend":{"topic":"t"}}`))
	if err != nil {
		t.Fatal(err)
	}
	if !cfg.enabled() {
		t.Error("absent `enabled` should default to enabled")
	}
}

func TestLoadConfigExplicitlyDisabled(t *testing.T) {
	cfg, err := loadConfig(writeConfig(t, `{"enabled":false,"backend":{"topic":"t"}}`))
	if err != nil {
		t.Fatal(err)
	}
	if cfg.enabled() {
		t.Error("explicit `enabled: false` should disable")
	}
}

func TestLoadConfigMissingFile(t *testing.T) {
	cfg, err := loadConfig(filepath.Join(t.TempDir(), "nope.json"))
	if err != nil {
		t.Fatalf("missing file should not error: %v", err)
	}
	if !cfg.enabled() {
		t.Error("zero config should be enabled")
	}
	if cfg.Backend.Topic != "" {
		t.Errorf("topic = %q, want empty", cfg.Backend.Topic)
	}
}

func TestLoadConfigInvalidJSON(t *testing.T) {
	if _, err := loadConfig(writeConfig(t, `not json`)); err == nil {
		t.Error("expected error for invalid JSON")
	}
}

func TestDefaultConfigPathRespectsXDG(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/tmp/xdg")
	want := filepath.Join("/tmp/xdg", "opencode", "notification-ntfy.json")
	if got := defaultConfigPath(); got != want {
		t.Errorf("defaultConfigPath() = %q, want %q", got, want)
	}
}
