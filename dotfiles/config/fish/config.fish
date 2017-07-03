# Put /usr/local/bin (Homebrew) before /usr/bin
# I could modify /etc/paths to put /usr/local/bin before /usr/bin
# but that might screw over system processes.
set PATH /usr/local/bin $PATH
set PATH $HOME/.local/bin $PATH

export EDITOR=nvim
export VISUAL=nvim

export NAME='Tom Fitzhenry'
export EMAIL='tom@tom-fitzhenry.me.uk'

export JAVA_HOME=(/usr/libexec/java_home)

if [ -f ~/.environment.local ]
	source ~/.environment.local
end

eval (python -m virtualfish)
