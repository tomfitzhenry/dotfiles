export EDITOR=mg

# Claude Code's TUI enables terminal mouse tracking but doesn't disable it on
# ungraceful SSH disconnect (laptop sleep + autossh reconnect), leaving the
# terminal reporting every mouse move as SGR sequences that the fresh login
# shell echoes as text spam. Disable mouse capture at the app level:
# https://github.com/anthropics/claude-code/issues/72648
export CLAUDE_CODE_DISABLE_MOUSE=1

shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=20000

if command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
fi

SSH_AUTH_SOCK="$(ssh-tpm-agent --print-socket)"
export SSH_AUTH_SOCK
