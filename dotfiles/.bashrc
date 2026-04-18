export EDITOR=mg

shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=20000

if command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
fi

SSH_AUTH_SOCK="$(ssh-tpm-agent --print-socket)"
export SSH_AUTH_SOCK

_rssh_completion() {
    if ! type -t _ssh >/dev/null; then
        _completion_loader ssh >/dev/null 2>&1
    fi
    if type -t _ssh >/dev/null; then
        _ssh
    fi
}
complete -F _rssh_completion rssh
