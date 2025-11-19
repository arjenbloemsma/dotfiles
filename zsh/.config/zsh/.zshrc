# Use Vi style editing
set -o vi

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Starship config in XDG_CONFIG_HOME
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# Node version manager
eval "$(fnm env --use-on-cd)"

# Aliases
alias vi='nvim'
alias blm='bloem'
alias trem='transmission-remote'
alias ul='ultralist'
alias mc='mc --nosubshell'
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

alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox -P'

# pnpm
export PNPM_HOME="~/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bloem, my swiss army knife
source "$XDG_CONFIG_HOME/bloem/bloem"

# Starship, the cross-shell prompt
eval "$(starship init zsh)"

# Zoxide, a smarter cd
eval "$(zoxide init --cmd cd zsh)"

# Fuzzy find
source <(fzf --zsh)
HISTFILE=~/.zsh_history
# Increase history size and setopt to `appendhistory`
# which is needed for Fuzzy find
HISTSIZE=20000
SAVEHIST=20000
setopt appendhistory

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
fastfetch

export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# Source local overrides (OS-specific configs)
[[ -f "$XDG_CONFIG_HOME/zsh/.zshrc.local" ]] && source "$XDG_CONFIG_HOME/zsh/.zshrc.local"
