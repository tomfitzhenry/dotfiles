[ -z "$PS1" ] && return

export EDITOR=mg

shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=20000

if command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
fi

export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-tpm-agent.sock"
