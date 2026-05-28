# Interactive bash startup file.
# Sourced for interactive non-login shells. .bash_profile sources us for login shells.

# Ensure XDG_CONFIG_HOME is set (defaults if not)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Vi-style command-line editing
set -o vi

# Machine-local overrides first (not in dotfiles repo, not stowed)
[[ -f "$XDG_CONFIG_HOME/shell/local.sh" ]] && source "$XDG_CONFIG_HOME/shell/local.sh"

# Shared shell config (env, aliases, functions)
for _f in env aliases functions; do
    [[ -f "$XDG_CONFIG_HOME/shell/$_f.sh" ]] && source "$XDG_CONFIG_HOME/shell/$_f.sh"
done
unset _f

# OS-specific (Linux distros; macOS uses zsh)
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "${ID,,}" in
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
fi

# Tool integrations
check_and_load "starship" 'eval "$(starship init bash)"'

# History
HISTFILE=~/.bash_history
HISTSIZE=20000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend 2>/dev/null || true
