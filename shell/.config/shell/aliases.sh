# Shell-agnostic aliases — sourced by both .zshrc and .bashrc.

# Editor
alias vi='nvim'

# Transmission CLI
alias trem='transmission-remote'

# Lazygit with custom configs
alias lazygit='lazygit --use-config-file="$XDG_CONFIG_HOME/lazygit/config.yml,$XDG_CONFIG_HOME/lazygit/green.yml"'

# List the git aliases below (handy reminder)
alias showg="grep -E '^alias g[^=]*=' $XDG_CONFIG_HOME/shell/aliases.sh"

# Git
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

# Kubernetes
alias k='kubectl'
