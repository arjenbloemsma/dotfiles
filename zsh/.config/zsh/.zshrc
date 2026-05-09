# Use Vi style editing
set -o vi

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Starship config in XDG_CONFIG_HOME
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# Notes vault
export NOTES_VAULT="$HOME/notes-vault"

# Machine-local overrides first (not in dotfiles repo, not stowed)
[[ -f "$XDG_CONFIG_HOME/zsh/.zshrc.local" ]] && source "$XDG_CONFIG_HOME/zsh/.zshrc.local"

# Source OS-specific configs (sets up PATH for Homebrew, etc)
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc.macos" ]] && source "$XDG_CONFIG_HOME/zsh/.zshrc.macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:l}" in
        ubuntu|debian)
            [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc.ubuntu" ]] && source "$XDG_CONFIG_HOME/zsh/.zshrc.ubuntu"
            ;;
        arch)
            [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc.arch" ]] && source "$XDG_CONFIG_HOME/zsh/.zshrc.arch"
            ;;
    esac
fi

# Helper function to check and load tools
check_and_load() {
    local cmd="$1"
    local init_cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        eval "$init_cmd"
    else
        echo "⚠️  $cmd not found - skipping initialization"
    fi
}

# Node version manager
check_and_load "fnm" 'eval "$(fnm env --use-on-cd)"'

# Aliases
alias vi='nvim'
alias trem='transmission-remote'
alias lazygit='lazygit --use-config-file="$XDG_CONFIG_HOME/lazygit/config.yml,$XDG_CONFIG_HOME/lazygit/green.yml"'
alias showg="cat ~/.config/zsh/.zshrc|grep 'alias.*git'"

alias g='git'
alias gd='git diff'
alias gdc='git diff --cached'
alias ga='git add'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gs='git status'
alias gss='git show --stat'
alias gl='git log --oneline -n '
alias glg='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'
alias gsl='git stash list'
alias gsm='git stash push -m'
alias gress='git reset --soft HEAD~1'
alias gresh='git reset --hard'

# Starship, the cross-shell prompt
check_and_load "starship" 'eval "$(starship init zsh)"'

# Zoxide, a smarter cd
check_and_load "zoxide" 'eval "$(zoxide init --cmd cd zsh)"'

# Fuzzy find
check_and_load "fzf" 'source <(fzf --zsh)'
HISTFILE=~/.zsh_history
# Increase history size and setopt to `appendhistory`
# which is needed for Fuzzy find
HISTSIZE=20000
SAVEHIST=20000
setopt appendhistory 2>/dev/null || true

# Yazi is a fast terminal file manager
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Fastfetch for the fancy system info
check_and_load "fastfetch" 'fastfetch'
