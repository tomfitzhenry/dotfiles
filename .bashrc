function mkcd() {
  mkdir -p "$1"
    cd "$1"
}

. ~/.environment

COLOR1="\[\033[0;36m\]" # Cyan
COLOR2="\[\033[0;32m\]" # Light Green
COLOR3="\[\033[0;36m\]" # Cyan
COLOR4="\[\033[0;31m\]" # Red
COLOR5="\[\033[0m\]"    # White

unset HISTFILE
export HISTCONTROL=ignoreboth

#alias sx='startx -- -nolisten tcp >& $HOME/.startx-errors'
alias sx="exec startx -- -nolisten tcp"
alias ls="ls -F --color"
alias c="clear"

# Convenience
alias irc='ssh -t codd screen -x'

# Debian stuff
alias sau="sudo sh -c 'aptitude update && aptitude safe-upgrade'"
alias sai="sudo aptitude install"

# Bash completion
if [ -z "$BASH_COMPLETION" ] && [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

upload_to_music_server() {
    while [ -n "$1" ];
    do
        curl -F upload=@"$1" http://music.compsoc.lan/; shift
    done
}

# gpg-agent
if test -f $HOME/.gpg-agent-info && \
    kill -0 `cut -d: -f 2 $HOME/.gpg-agent-info` 2>/dev/null; then
    GPG_AGENT_INFO=`cat $HOME/.gpg-agent-info`
    export GPG_AGENT_INFO
else
    eval `gpg-agent --daemon`
    echo $GPG_AGENT_INFO >$HOME/.gpg-agent-info
fi

source ~/.bashrc-private
