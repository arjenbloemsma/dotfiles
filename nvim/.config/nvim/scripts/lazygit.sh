#!/usr/bin/env bash

window_name="lazygit"

tmux_running=$(pgrep tmux)
if [[ -z $tmux_running ]]; then
	echo "Tmux is not running"
	exit 1
fi

# TMUX is a special variable that is set when the current terminal
# is running inside a tmux session, so when this is empty, we know
# that we are not running inside tmux
if [[ -z $TMUX ]]; then
	echo "This terminal is not running inside a tmux session"
	exit 1
fi

if [[ $(tmux list-windows | grep $window_name) ]]; then
	tmux select-window -t $window_name
else
	tmux new-window -n $window_name 'lazygit --use-config-file="$XDG_CONFIG_HOME/lazygit/config.yml,$XDG_CONFIG_HOME/lazygit/green.yml"'
fi
exit 0
