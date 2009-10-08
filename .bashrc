source ~/.profile

# Bash completion
if [ -z "$BASH_COMPLETION" ] && [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

unset HISTFILE
export HISTCONTROL=ignoreboth
