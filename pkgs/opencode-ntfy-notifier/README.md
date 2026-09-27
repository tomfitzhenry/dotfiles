# opencode-ntfy-notifier

Shows a desktop notification for each ntfy event and, on click, focuses the
niri workspace named after the session.

Reads topic/server/token from `~/.config/opencode/notification-ntfy.json` (the
same file as the opencode-ntfy plugin). Overrides: `-config`, `-topic` /
`OPENCODE_NTFY_TOPIC`, `-server` / `OPENCODE_NTFY_SERVER`, `-token` /
`OPENCODE_NTFY_TOKEN`.

Must run inside the niri session: it needs `$NIRI_SOCKET` and
`$DBUS_SESSION_BUS_ADDRESS`, with noctalia as the notification daemon.
