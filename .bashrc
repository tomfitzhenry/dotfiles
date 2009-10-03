function mkcd() {
  mkdir -p "$1"
    cd "$1"
}


COLOR1="\[\033[0;36m\]" # Cyan
COLOR2="\[\033[0;32m\]" # Light Green
COLOR3="\[\033[0;36m\]" # Cyan
COLOR4="\[\033[0;31m\]" # Red
COLOR5="\[\033[0m\]"    # White
export PS1="$COLOR1\u$COLOR2\h$COLOR1\w$COLOR4 :: $COLOR5"

export PATH=$HOME/bin:$HOME/usr/bin/:$HOME/usr/local/bin/:/usr/lib/postgresql/8.3/bin:$PATH:/opt/WorldOfGoo/
export LANG=en_GB.utf-8

export BROWSER=/usr/bin/firefox
export EDITOR=/usr/bin/vim
export VISUAL=/usr/bin/vim

export NNTPSERVER=news.virginmedia.com

unset HISTFILE
export HISTCONTROL=ignoreboth

# Stops 'less' from writing to '~/.lesshst"
export LESSHISTFILE="-"

# On systems that supported ipv6, some mpd clients wouldn't work
# because they look at 'localhost' by default and they looked for
# ipv6 localhost. Explicately putting 127.0.0.1 (i.e. ipv4 localhost)
# worked. MPD runs on ipv4 localhost.
export MPD_HOST=127.0.0.1

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
