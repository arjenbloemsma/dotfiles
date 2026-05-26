# Sourced by zsh on every invocation. Set XDG paths early so that .zshrc
# (located under $ZDOTDIR) gets found.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
