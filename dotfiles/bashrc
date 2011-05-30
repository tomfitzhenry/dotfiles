source ~/.profile

function mkcd() {
  mkdir -p "$1"
    cd "$1"
}

upload_to_music_server() {
    while [ -n "$1" ];
    do
        curl -F upload=@"$1" http://music.compsoc.lan/; shift
    done
}

# Bash completion
if [ -z "$BASH_COMPLETION" ] && [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

unset HISTFILE
export HISTCONTROL=ignoreboth
