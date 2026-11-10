# Interactive bash startup file.
# Sourced for interactive non-login shells. .bash_profile sources us for login shells.

# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# Nothing to do for non-interactive shells (ssh commands, scripts)
[[ $- != *i* ]] && return

# Ensure XDG_CONFIG_HOME is set (defaults if not)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Omarchy's shell setup first (mise, zoxide, fzf, aliases, its themed
# prompt), so ours overrides where both set the same thing
_omarchy_bash=/usr/share/omarchy/default/bash
[[ -r "$_omarchy_bash/rc" ]] && source "$_omarchy_bash/rc"

# Vi-style command-line editing
set -o vi
# Omarchy's key bindings only reach the default key table, so add them
# to the vi one too
[[ -r "$_omarchy_bash/inputrc" ]] && bind -m vi-insert -f "$_omarchy_bash/inputrc"
# Vi insert mode leaves Ctrl-l unbound
bind -m vi-insert '"\C-l": clear-screen'

# Machine-local overrides first (not in dotfiles repo, not stowed)
[[ -f "$XDG_CONFIG_HOME/shell/local.sh" ]] && source "$XDG_CONFIG_HOME/shell/local.sh"

# Shared shell config (env, aliases, functions)
for _f in env aliases functions; do
    [[ -f "$XDG_CONFIG_HOME/shell/$_f.sh" ]] && source "$XDG_CONFIG_HOME/shell/$_f.sh"
done
unset _f

# OS-specific (Linux distros; macOS uses zsh). Only ID is read, so the
# other os-release fields do not stay behind in the shell.
_os_id=$([[ -f /etc/os-release ]] && . /etc/os-release && echo "${ID,,}")
case "$_os_id" in
    ubuntu|debian)
        [[ -f "$XDG_CONFIG_HOME/shell/ubuntu.sh" ]] && source "$XDG_CONFIG_HOME/shell/ubuntu.sh"
        ;;
    arch)
        [[ -f "$XDG_CONFIG_HOME/shell/arch.sh" ]] && source "$XDG_CONFIG_HOME/shell/arch.sh"
        ;;
    fedora)
        [[ -f "$XDG_CONFIG_HOME/shell/fedora.sh" ]] && source "$XDG_CONFIG_HOME/shell/fedora.sh"
        ;;
esac
unset _os_id

# Tool integrations (host only, containers run a bare prompt)
if [[ -r "$_omarchy_bash/rc" ]]; then
    # Omarchy already started starship; keep its prompt, which follows its theme
    unset STARSHIP_CONFIG
elif [[ ! -f /.dockerenv ]] && [[ ! -f /run/.containerenv ]]; then
    check_and_load "starship" 'eval "$(starship init bash)"'
fi
unset _omarchy_bash

# History
HISTFILE=~/.bash_history
HISTSIZE=32768
HISTFILESIZE=32768
# Skip duplicates and commands that start with a space
HISTCONTROL=ignoreboth
shopt -s histappend 2>/dev/null || true
