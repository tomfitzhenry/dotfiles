export EDITOR=mg

shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=20000

if command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
fi
